# consumer/app/controllers/videos_controller.rb
class VideosController < ApplicationController
  def index
    @videos = Dir.glob(Rails.root.join('public', 'received_videos', '*.mp4')).map do |path|
      {
        name: File.basename(path),
        url: "received_videos/#{URI.encode_www_form_component(File.basename(path))}",
        # size: number_to_human_size(File.size(path)),
        created_at: File.ctime(path)
      }
    end.sort_by { |v| v[:created_at] }.reverse
  end
end