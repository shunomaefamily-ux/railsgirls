Rails.application.routes.draw do
  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :people, only: [:show]

  resources :medication_items do
    post :consume_one, on: :member

    resources :medication_lots, only: [:new, :create] do
      patch :discard, on: :member
    end
  end

  resources :imports, only: %i[create show] do
    collection do
      get :scan
    end
    member do
      post :register
    end
  end

  get  "people/:person_id/manual_imports/new", to: "imports#manual_new", as: :new_person_manual_import
  post "people/:person_id/manual_imports",     to: "imports#manual_create", as: :person_manual_imports

 namespace :api do
    get "people", to: "people#index"
    get "check_request/current", to: "check_requests#current"
    post "check_requests/:id/confirm", to: "check_requests#confirm"
  end

end
