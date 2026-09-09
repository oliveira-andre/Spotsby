namespace :hotwire do
  namespace :ios do
    resources :configurations, only: [] do
      collection do
        get :v1
      end
    end
  end
end