require 'dotenv/load'
require 'fileutils'

# Load environment variables from .env file
Dotenv.load('../.env')  # Go up one level from server/ to find .env


# Ensure that the .env variables are loaded correctly
puts "Configuration:"
port = ENV['VIDEO_SERVER_PORT']
bound_addr = ENV['BOUND_ADDR']
video_dir = ENV['VIDEO_DIRECTORY']

puts "Loaded VIDEO SERVER PORT: #{port}"
puts "Loaded BOUND_ADDR: #{bound_addr}"

# print the video directory whole path
puts "Loaded VIDEO_DIRECTORY: #{video_dir}"
puts "Loaded VIDEO_DIRECTORY (full path): #{File.expand_path(video_dir)}"

$LOAD_PATH << '.'
require 'consumer'

thread = Thread.start(
    VideoServer.new(ENV)
) do |server| 
    server.mainloop 
end

thread.join