Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token

  get "search", to: "home#search", as: :search
  get "search/results", to: "home#search_results", as: :search_results
  get "library", to: "home#library", as: :library
  get "manage", to: "home#manage", as: :manage

  resources :play_histories, only: %i[destroy]
  resources :favorites, only: %i[] do
    collection do
      post   "songs/:id",                        action: :create_song,     as: :song
      delete "songs/:id",                        action: :destroy_song
      post   "songs/:id/modal",                  action: :playlists_modal, as: :song_modal
      post   "songs/:id/playlists/:playlist_id", action: :add_to_playlist, as: :add_song_to_playlist
      post   "albums/:id",                       action: :create_album,    as: :album
      delete "albums/:id",                       action: :destroy_album
    end
  end
  resources :categories, only: %i[show]
  resources :albums, only: %i[show]
  resources :authors, only: %i[show] do
    member do
      get :all_songs
    end
  end
  resources :players, only: %i[show] do
    collection do
      post :next
      post :previous
    end
  end

  namespace :admin do
    get "dashboard", to: "dashboard#index", as: :dashboard
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
