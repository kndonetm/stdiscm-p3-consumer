require 'dotenv/load'

$LOAD_PATH << '.'

require 'consumer'

thread = Thread.start(
    VideoServer.new(ENV["PORT"], ENV["BOUND_ADDR"], ENV["VIDEO_DIRECTORY"])
) do |server| 
    server.mainloop 
end
thread.join