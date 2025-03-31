require 'socket'
require 'json'

class VideoServer 
    attr_reader :port, :server

    def initialize(port, hostname, video_directory)
        @port = port
        @hostname = hostname
        @video_directory = video_directory
    end

    def receive_command(socket)
        size = socket.read(8)
        if not size then return end
        size = size.unpack1('q')
        puts size
        return socket.read(size)
    end

    def handle_client(client)
        puts "Accepting client from #{client.local_address.ip_address}"
        
        while raw_cmd = receive_command(client) do 
            cmd = JSON.parse(raw_cmd)
        
            puts cmd
            
            if cmd["action"] == "sendFile" then
                data = client.read(cmd["size"])
        
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
        @server = TCPServer.open(@hostname, @port)
        puts "Listening on port #{@port}"

        loop do
            Thread.start(@server.accept) do |client| self.handle_client(client) end
        end
    end
end