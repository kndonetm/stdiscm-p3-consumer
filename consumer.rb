require 'socket'
require 'json'

class VideoServer 
    attr_reader :port, :server

    def initialize(settings)
        @port = settings["PORT"].to_i
        @bound_addr = settings["BOUND_ADDR"]
        @video_directory = settings["VIDEO_DIRECTORY"]
        @num_threads = settings["NUM_CONSUMER_THREADS"].to_i
        @queue_length = settings["MAX_QUEUE_LENGTH"].to_i

        @threads = []
        
        for i in 0..@num_threads - 1 do
            thread = Thread.start(i) do |id| 
                worker_thread id
            end
            
            thread["status"] = ["idle"]
            thread["status"].extend(MonitorMixin)
            thread["status_cond"] = thread["status"].new_cond

            thread["port"] = @port + i + 1

            @threads << thread
        end

        @queue = []

        @ready_to_accept = []
        @ready_to_accept.extend(MonitorMixin)
        @ready_to_accept_cond = @ready_to_accept.new_cond
    end

    def worker_thread(id)
        puts "Created consumer thread with id #{id}"
        
        loop do
            Thread.current["status"].synchronize do
                Thread.current["status_cond"].wait_while { Thread.current["status"][0] == "idle" }
            end

            num_videos = Thread.current["num_videos"]
            producer_ip = Thread.current["ip"]
            request_id = Thread.current["request_id"]

            puts "Host thread #{id} assigned to receive #{num_videos} videos from producer #{producer_ip} thread #{request_id}"

            @ready_to_accept.synchronize do
                @ready_to_accept << Thread.current
                @ready_to_accept_cond.signal
            end

            puts "Thread #{id} opening TCP server to #{producer_ip} on port #{Thread.current["port"]}"
            server = TCPServer.open(producer_ip, Thread.current["port"])
            client = server.accept
            
            num_videos.times do 
                cmd = receive_json(client)
                if cmd["action"] == "sendFile" then
                    receive_video cmd["size"], client, File.join(@video_directory, cmd["filename"])
                end
            end

            client.close
            server.close

            set_thread_status Thread.current, "idle"
        end
    end

    def set_thread_status(thread, status)
        thread["status"][0] = status
    end

    def assign_thread(thread, num_videos, ip, request_id)
        thread["status"].synchronize do 
            thread["num_videos"] = num_videos
            thread["ip"] = ip
            thread["request_id"] = request_id
            set_thread_status thread, "active"
            thread["status_cond"].signal
        end
    end

    def get_free_threads
        @threads.each_with_index.select { |thread, id|
            thread["status"][0] == "idle" 
        }
    end

    def get_num_videos_in_queue
        @queue.map {|ip, id, num_videos|
            num_videos
        }
        .sum
    end

    def receive_video(size, socket, filepath)
        file = File.new(filepath, "wb") 
        num_full_blocks = size / 65536
        num_full_blocks.times do 
            file.write(socket.read(65536))
        end
        file.write(socket.read(size - (num_full_blocks * 65536)))

        file.close
        send_ok socket

        puts "Received video of size #{size} from client"
        puts "Created new file in #{filepath}"
    end

    def receive_json(socket)
        size = socket.read(8)
        if not size then return end
        size = size.unpack1('q')
        json = socket.read(size)
        puts "Received #{json}"
        send_ok socket
        return JSON.parse(json)
    end

    def send_json(msg, socket)
        puts "Attempting to send #{msg} to #{socket.local_address.ip_address}"
        socket.write [msg.length].pack("q")
        socket.write msg
    end

    def send_ok(socket)
        socket.write("OK")
    end

    def request_threads_response(assigned_requests, queued_requests)
        return JSON.generate({
            assigned: assigned_requests,
            queued: queued_requests
        })
    end

    def thread_ready_response(producer_thread_id, port)
        return JSON.generate({
            id: producer_thread_id,
            port: port
        })
    end

    def handle_client(client)
        client_ip = client.local_address.ip_address
        puts "Accepting client from #{client_ip}"
        
        while cmd = receive_json(client) do 
            
            if cmd["action"] == "sendFile" then
                receive_video cmd["size"], client, File.join(@video_directory, cmd["filename"])

            elsif cmd["action"] == "requestThreads" then
                thread_requests = cmd["video_counts"]
                num_requested_threads = thread_requests.length

                free_threads = get_free_threads
                num_assigned_threads = [num_requested_threads, free_threads.length].min
                assigned_threads = free_threads[0, num_assigned_threads]
                assigned_threads.each_with_index.each do |thread_info, request_id|
                    id = thread_info[1]
                    assign_thread @threads[id], thread_requests[request_id], client_ip, request_id
                    puts "Assigned thread #{id} to request ID #{request_id}"
                end

                assigned_requests = assigned_threads.map {|thread, id| id}
                queued_requests = []

                if num_requested_threads > num_assigned_threads then
                    current_queue_size = get_num_videos_in_queue
                    space_remaining_in_queue = @queue_length - current_queue_size
                    unassigned_thread_requests = thread_requests.each_with_index.to_a[
                        num_assigned_threads..thread_requests.length
                    ]
                    
                    space_occupied_by_requests = 0

                    unassigned_thread_requests.each do |num_videos, id|
                        if space_occupied_by_requests + num_videos > space_remaining_in_queue then
                            # add as many remaining videos as possible to the queue
                            if space_occupied_by_requests != space_remaining_in_queue then
                                @queue << [client_ip, id, space_remaining_in_queue - space_occupied_by_requests]
                                puts "Queued #{space_remaining_in_queue - space_occupied_by_requests} videos from #{client_ip} producer thread #{id}"
                                queued_requests << id
                            end

                            break
                        end

                        space_occupied_by_requests += num_videos
                        @queue << [client_ip, id, num_videos]
                        queued_requests << id
                        puts "Queued #{num_videos} videos from #{client_ip} producer thread #{id}"
                    end
                end

                send_json request_threads_response(assigned_requests, queued_requests), client

                assigned_requests.each do
                    @ready_to_accept.synchronize do
                        @ready_to_accept_cond.wait_while { @ready_to_accept.empty? }
                        ready_thread = @ready_to_accept.shift
                        send_json thread_ready_response(ready_thread["request_id"], ready_thread["port"]), client
                    end
                end

            elsif cmd["action"] == "exit" then
                puts "Connection closed by client #{client_ip}"
                client.close
                return
            end
        end
    end

    def mainloop
        @server = TCPServer.open(@bound_addr, @port)
        puts "Listening on port #{@port} with bound address #{@bound_addr}"

        loop do
            Thread.start(@server.accept) do |client| self.handle_client(client) end
        end
    end
end