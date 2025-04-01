# this controller gets the videos and displays to your home page
class VideosController < ApplicationController
    def display  
        # for testing, change the path to your testing folder, it gets in the folder and stores every video file to @video_files
        @video_path = Rails.root.join('../../videosC')   
        Rails.logger.debug("Video Path: #{@video_path}")
        if Dir.exist?(@video_path)
            @video_files = Dir.glob(@video_path.join('*')).map { |file| File.basename(file) }
          else
            @video_files = []
          end
          Rails.logger.debug("Video Files Found: #{@video_files.inspect}")
      end
end
