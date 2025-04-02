require 'socket'
require 'json'

class VideoServer 
    attr_reader :port, :server

    def initialize(settings)
        @port = settings["PORT"]
        @bound_addr = settings["BOUND_ADDR"]
        @video_directory = settings["VIDEO_DIRECTORY"]
    end

    def receive_video(size, socket)
        data = socket.read size
        puts "Received video of size #{size} from client"
        send_ok socket
        return data
    end

    def receive_command(socket)
        size = socket.read(8)
        if not size then return end
        size = size.unpack1('q')
        cmd = socket.read(size)
        puts "Received command #{cmd}"
        send_ok socket
        return cmd
    end

    def send_ok(socket)
        puts "Sent OK"
        socket.write("OK")
    end

    def handle_client(client)
        puts "Accepting client from #{client.local_address.ip_address}"
        
        while raw_cmd = receive_command(client) do 
            cmd = JSON.parse(raw_cmd)
            
            if cmd["action"] == "sendFile" then
                data = receive_video cmd["size"], client
        
                filepath = File.join(@video_directory, cmd["filename"])
                file = File.new(filepath, "wb") 
                file.write(data)
                file.close
                puts "Created new file in #{filepath}"
            elsif cmd["action"] == "exit" then
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