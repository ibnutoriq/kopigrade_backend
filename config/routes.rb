Rails.application.routes.draw do
  root "admin/dashboard#show"

  # Rails 8 session-based auth
  resource :session
  resources :passwords, param: :token

  namespace :api do
    namespace :v1 do
      resources :scan_results, only: [ :create, :show ]
      resources :market_prices, only: [ :index ]
    end
  end

  namespace :admin do
    get "dashboard", to: "dashboard#show"
    resources :scan_results, only: [ :index, :show, :destroy ]
    resources :market_prices
    resources :users
    post "market_prices/scrape_now", to: "market_prices#scrape_now", as: :scrape_now_market_prices
    get "exports/scan_results", to: "exports#scan_results", as: :export_scan_results,
        defaults: { format: :csv }
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
