# home controller, controlls home page
class HomeController < ApplicationController
  def index
    # since video will be displayed in homepage, assign new controller instance of video_controller and let it help retrive the videos
    @video_controller = VideosController.new
    @video_controller.display
    @video_files = @video_controller.instance_variable_get(:@video_files)
  end
end
