Rails.application.routes.draw do
  # Root path to video index
  root "videos#index"

  # Routes for videos
  get "/videos/:id", to: "videos#show", as: :video
  get "videos/index", to: "videos#index"

  # Optional: route to view video queue status
  get 'videos/status', to: 'videos#status', as: :video_status


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
