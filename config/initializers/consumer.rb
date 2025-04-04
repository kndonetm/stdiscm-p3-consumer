require "socket"
require "json"
require "resolv"
require "dotenv/load"

class VideoServer
    attr_reader :port, :server

    def initialize(settings)
        @port = string_to_i_safe(settings["PORT"], "PORT", min=0, max=65535)
        @bound_addr = settings["BOUND_ADDR"]
        @video_directory = settings["VIDEO_DIRECTORY"]
        @num_threads = string_to_i_safe(settings["NUM_CONSUMER_THREADS"], "NUM_CONSUMER_THREADS", min=1, max=256)
        @queue_length = string_to_i_safe(settings["MAX_QUEUE_LENGTH"], "MAX_QUEUE_LENGTH", min=0, max=256)

        if not File.directory? @video_directory then
            raise ArgumentError.new("VIDEO_DIRECTORY is not a directory, got \"#{@video_directory}\"")
        end

        if not !!(@bound_addr =~ Resolv::AddressRegex) and not @bound_addr == "localhost" then
            raise ArgumentError.new("BOUND_ADDR is not a valid IP address, got \"#{@bound_addr}\"")
        end

        @threads = []

        @queue = []
        @queue.extend(MonitorMixin)
        @queue_cond = @queue.new_cond

        @ready_to_accept = []
        @ready_to_accept.extend(MonitorMixin)
        @ready_to_accept_cond = @ready_to_accept.new_cond

        for i in 0..@num_threads - 1 do
            thread = Thread.start(i) do |id|
                worker_thread id
            end

            thread["status"] = [ "idle" ]
            thread["status"].extend(MonitorMixin)
            thread["status_cond"] = thread["status"].new_cond

            @threads << thread
        end
    end

    def string_to_i_safe(string, variable_name = "variable", min = nil, max = nil)
        val = string.to_i

        if val.to_s != string then
            raise ArgumentError.new("Invalid environment configuration: #{variable_name} must be an integer, found #{string}")
        end

        if min != nil and val < min then
            raise ArgumentError.new("Invalid environment configuration: #{variable_name} must be at least #{min}, found #{val}")
        end

        if max != nil and val > max then
            raise ArgumentError.new("Invalid environment configuration: #{variable_name} must be at most #{max}, found #{val}")
        end

        val
    end

    def worker_thread(id)
        puts "Created consumer thread with id #{id}"

        loop do
            request = nil
            @queue.synchronize do
                @queue_cond.wait_while { @queue.empty? }
                request = @queue.shift
            end

            producer_ip, request_id, num_videos = request
            worker_thread_port = @port + id + 1

            puts "Host thread #{id} assigned to receive #{num_videos} videos from producer #{producer_ip} thread #{request_id}"

            @ready_to_accept.synchronize do
                @ready_to_accept << [ request_id, worker_thread_port, num_videos ]
                @ready_to_accept_cond.signal
            end

            puts "Thread #{id} opening TCP server to #{producer_ip} on port #{worker_thread_port}"
            server = TCPServer.open(producer_ip, worker_thread_port)
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

    def add_to_queue(requests)
        @queue.synchronize do
            requests.each do |request|
                @queue << request
            end
            @queue_cond.signal
        end
    end

    def get_num_free_threads
        @threads.each_with_index.select { |thread, id|
            thread["status"][0] == "idle"
        }
        .length
    end

    def get_num_videos_in_queue
        @queue.map { |ip, id, num_videos|
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
        size = size.unpack1("q")
        json = socket.read(size)
        puts "Received #{json}"
        send_ok socket
        JSON.parse(json)
    end

    def send_json(msg, socket)
        puts "Attempting to send #{msg} to #{socket.local_address.ip_address}"
        socket.write [ msg.length ].pack("q")
        socket.write msg
    end

    def send_ok(socket)
        socket.write("OK")
    end

    def request_threads_response(assigned_requests, queued_requests)
        JSON.generate({
            assigned: assigned_requests,
            queued: queued_requests
        })
    end

    def thread_ready_response(producer_thread_id, port, num_videos)
        JSON.generate({
            id: producer_thread_id,
            port: port,
            num_videos: num_videos
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
                current_queue_size = get_num_videos_in_queue
                space_remaining_in_queue = @queue_length - current_queue_size
                free_threads = get_num_free_threads

                num_assigned_threads = [ num_requested_threads, free_threads ].min
                assigned_requests = (0..num_assigned_threads-1).map { |request_id|
                    [ client_ip, request_id, thread_requests[request_id] ]
                }

                add_to_queue assigned_requests
                assigned_requests.each do |ip, id, num_videos|
                    puts "Added assigned request ID #{id} from #{ip} to upload #{num_videos}} to queue"
                end

                queued_requests = []

                if num_requested_threads > num_assigned_threads then
                    unassigned_thread_requests = thread_requests.each_with_index.to_a[
                        num_assigned_threads..thread_requests.length
                    ]

                    space_occupied_by_requests = 0

                    unassigned_thread_requests.each do |num_videos, id|
                        if space_occupied_by_requests + num_videos > space_remaining_in_queue then
                            # add as many remaining videos as possible to the queue
                            if space_occupied_by_requests != space_remaining_in_queue then
                                queued_requests << [ client_ip, id, space_remaining_in_queue - space_occupied_by_requests ]
                            end
                            break
                        end

                        space_occupied_by_requests += num_videos
                        queued_requests << [ client_ip, id, num_videos ]
                    end

                    add_to_queue queued_requests
                    queued_requests.each do |ip, id, num_videos|
                        puts "Added queued request ID #{id} from #{ip} to upload #{num_videos} video to queue"
                    end
                end

                assigned_request_ids = (0..num_assigned_threads-1).to_a
                queued_request_ids = queued_requests.map { |_, id, _| id }

                send_json request_threads_response(assigned_request_ids, queued_request_ids), client

                (assigned_request_ids.length + queued_request_ids.length).times do
                    @ready_to_accept.synchronize do
                        @ready_to_accept_cond.wait_while { @ready_to_accept.empty? }
                        request_id, port, num_videos = @ready_to_accept.shift
                        send_json thread_ready_response(request_id, port, num_videos), client
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

Thread.start(
    VideoServer.new(ENV)
) do |server|
    server.mainloop
end
