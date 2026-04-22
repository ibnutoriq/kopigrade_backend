Rails.application.routes.draw do
  root "web/home#show"

  # Public PWA layer
  scope module: :web, as: :web do
    resources :scans, only: [ :new, :create, :show ]
    get "harga",   to: "prices#index",  as: :prices
    get "tentang", to: "pages#about",   as: :about
  end

  # Rails 8 session-based auth
  resource :session
  resources :passwords, param: :token

  namespace :api do
    namespace :v1 do
      resources :scan_results, only: [ :create, :show ]
      resources :market_prices, only: [ :index ]
    end
  end

  get "/admin", to: redirect("/admin/dashboard")

  namespace :admin do
    get "dashboard", to: "dashboard#show"
    resources :scan_results, only: [ :index, :show, :destroy ]
    resources :market_prices do
      collection { post :scrape_now }
    end
    resources :users
    get "exports/scan_results", to: "exports#scan_results", as: :export_scan_results,
        defaults: { format: :csv }
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
