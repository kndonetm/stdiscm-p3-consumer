Rails.application.routes.draw do
  # Root path to video index
  root "videos#index"

  # Routes for videos
  get "/videos/:id", to: "videos#show", as: :video
  get "videos/index", to: "videos#index"

  # Optional: route to view video queue status
  get 'videos/status', to: 'videos#status', as: :video_status

end
