Rails.application.routes.draw do
  get "people/show"
  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

resources :medication_items do
  resources :medication_lots, only: [:new, :create]
end


resources :medication_items do
  post :consume_one, on: :member
  resources :medication_lots, only: [:new, :create]
end

resources :medication_items do
  resources :medication_lots, only: [:new, :create] do
    patch :discard, on: :member
  end
  post :consume_one, on: :member
end

resources :people do
  resources :imports, only: [:create] do
    collection do
      get :scan
    end
  end
end

  
end
