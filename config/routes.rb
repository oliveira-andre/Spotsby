Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resource :account, only: %i[show update destroy]
  resources :passwords, param: :token

  get "search", to: "home#search", as: :search
  get "search/results", to: "home#search_results", as: :search_results
  get "library", to: "home#library", as: :library
  get "manage", to: "home#manage", as: :manage
  get "profile", to: "home#profile", as: :profile
  get "recent_albums", to: "home#recent_albums", as: :recent_albums
  get "recent_artists", to: "home#recent_artists", as: :recent_artists
  get "home_all", to: "home#all", as: :home_all

  resources :play_histories, only: %i[destroy]

  resources :favorites, only: %i[] do
    collection do
      post   "songs/:id",                        action: :create_song,          as: :song
      delete "songs/:id",                        action: :destroy_song
      post   "songs/:id/modal",                  action: :playlists_modal,      as: :song_modal
      post   "songs/:id/playlists/:playlist_id", action: :add_to_playlist,      as: :add_song_to_playlist
      delete "songs/:id/playlists/:playlist_id", action: :remove_from_playlist, as: :remove_song_from_playlist
      post   "albums/:id",                       action: :create_album,         as: :album
      delete "albums/:id",                       action: :destroy_album
    end
  end

  resources :categories, only: %i[show]

  resources :playlists, only: %i[show new create] do
    member do
      get :song_picker
      patch :update_position
      post :random_song
    end

    collection do
      get :create_options
    end

    resources :songs, only: [], controller: "playlist_songs" do
      member do
        patch :update_position
      end
    end
  end

  resources :albums, only: %i[show] do
    member do
      post :random_song
    end

    resources :songs, only: [], controller: "album_songs" do
      member do
        patch :update_position
      end
    end
  end

  resources :authors, only: %i[show] do
    member do
      get :all_songs
      post :random_song
    end
  end

  resources :players, only: %i[show] do
    collection do
      post :next
      post :previous
      post :toggle_random
    end
  end

  namespace :admin do
    get "dashboard", to: "dashboard#index", as: :dashboard
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
