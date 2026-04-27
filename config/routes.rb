Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token

  get "search", to: "home#search", as: :search
  get "library", to: "home#library", as: :library
  get "manage", to: "home#manage", as: :manage

  namespace :admin do
    get "dashboard", to: "dashboard#index", as: :dashboard
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
