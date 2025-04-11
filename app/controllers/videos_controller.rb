# consumer/app/controllers/videos_controller.rb
class VideosController < ApplicationController
  def index
    @videos = Dir.glob(Rails.root.join("public/received_videos", "*.mp4")).map do |path|
      {
        name: File.basename(path)[32..-1],  # skip video hash
        filename: URI.encode_www_form_component(File.basename(path)), # added this

        url: "received_videos/#{URI.encode_www_form_component(File.basename(path))}",
        # size: number_to_human_size(File.size(path)),
        created_at: File.ctime(path)
      }
    end.sort_by { |v| v[:created_at] }.reverse
  end

  # added
  def stream
    filename = "#{URI.decode_www_form_component(params[:name])}#{'.mp4' unless params[:name].ends_with?('.mp4')}"

    path = Rails.root.join("public/received_videos", filename)

    Rails.logger.info "Streaming request for: #{filename}"
    Rails.logger.info "Resolved path: #{path}"

    if File.exist?(path)
      send_file path, type: "video/mp4", disposition: "inline"
    else
      render plain: "Video not found", status: :not_found
    end
  end
end
