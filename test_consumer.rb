require 'dotenv/load'

$LOAD_PATH << '.'

require 'consumer'

thread = Thread.start(VideoServer.new(ENV["PORT"])) do |server| server.mainloop end
thread.join