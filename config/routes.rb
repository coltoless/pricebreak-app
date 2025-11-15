Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  post 'notify', to: 'notifications#create'
  get 'search', to: 'search#index'
  
  # Flight Price Filter routes - ENABLED for local development
  get 'flight-filter', to: 'flight_filters#index'
  get 'flight-filter/demo', to: 'flight_filters#demo'
  resources :flight_filters do
    member do
      patch :activate
      patch :deactivate
      post :duplicate
      post :test_price_check
    end
    collection do
      post :bulk_action
    end
  end
  
  resources :flight_alerts, only: [:index, :show, :destroy] do
    member do
      patch :pause
      patch :resume
      patch :expire
      patch :update_quality
      post :test_notification
    end
    collection do
      post :bulk_action
      get :analytics
      get :export
    end
  end
  
  # Flight Dashboard
  get 'dashboard', to: 'flight_dashboard#index', as: :flight_dashboard
  
  # Unsubscribe route (public)
  get 'unsubscribe/:token', to: 'flight_alerts#unsubscribe', as: :unsubscribe

  # Firebase Authentication routes
  get 'sign-in', to: 'auth#sign_in', as: :sign_in
  
  # Account Dashboard routes
  get 'account', to: 'account#index', as: :account
  get 'account/settings', to: 'account#settings', as: :account_settings
  
  namespace :api do
    post 'auth/login', to: 'auth#login'
    post 'auth/register', to: 'auth#register'
    delete 'auth/logout', to: 'auth#logout'
    get 'auth/me', to: 'auth#me'
    get 'auth/dashboard', to: 'auth#dashboard'
    put 'auth/profile', to: 'auth#update_profile'
    put 'auth/preferences', to: 'auth#update_preferences'
    
    # Flight Filter API routes
    resources :flight_filters, only: [:index, :show, :create, :update, :destroy] do
      member do
        post :duplicate
        get :monitoring_schedule
      end
      collection do
        post :bulk_action
        post :validate_route
        post :check_duplicates
      end
    end
  end
  
  # Flight Price Filter routes - Commented out for coming soon mode (production)
  # get 'flight-filter', to: 'flight_filters#index'
  # namespace :api do
  #   resources :flight_filters, only: [:create, :index, :show, :destroy]
  # end

  # Development-only routes
  if Rails.env.development?
    namespace :dev do
      get 'search', to: 'search#index'
      get 'search/results', to: 'search#results'
      resources :price_alerts, only: [:index, :create, :destroy]
    end
    
    # Demo routes for testing
    namespace :demo do
      get 'airport_autocomplete', to: 'demo#airport_autocomplete'
    end
  end

  resources :launch_subscribers, only: [:create]
  
  # Monitoring system routes
  namespace :monitoring do
    get 'dashboard', to: 'dashboard'
    post 'start', to: 'start_monitoring'
    post 'stop', to: 'stop_monitoring'
    post 'restart', to: 'restart_monitoring'
    post 'check_filter/:filter_id', to: 'check_filter', as: 'check_filter'
    post 'trigger_analysis', to: 'trigger_analysis'
    post 'trigger_cleanup', to: 'trigger_cleanup'
    post 'trigger_quality_update', to: 'trigger_quality_update'
    post 'send_test_notification', to: 'send_test_notification'
    get 'metrics', to: 'metrics'
    get 'recent_alerts', to: 'recent_alerts'
    get 'logs', to: 'logs'
  end
  
  # Public monitoring endpoints
  get 'monitoring/status', to: 'monitoring#status'
  get 'monitoring/health', to: 'monitoring#health'
  
  # Analytics routes
  namespace :analytics do
    get 'dashboard', to: 'dashboard'
    get 'user_dashboard', to: 'user_dashboard'
    get 'metrics', to: 'metrics'
    get 'user_metrics', to: 'user_metrics'
    get 'export', to: 'export'
    get 'trends', to: 'trends'
    get 'ab_test_results', to: 'ab_test_results'
    get 'user_segments', to: 'user_segments'
    get 'route_analysis', to: 'route_analysis'
    get 'seasonal_analysis', to: 'seasonal_analysis'
    get 'monitoring_dashboard', to: 'monitoring_dashboard'
  end
  
  # Testing and quality routes
  namespace :testing do
    get 'comprehensive', to: 'comprehensive'
    get 'quality_report', to: 'quality_report'
    post 'run_tests', to: 'run_tests'
  end
  
  # Edge case handling routes
  namespace :edge_cases do
    get 'handle', to: 'handle'
    get 'statistics', to: 'statistics'
    post 'run_handling', to: 'run_handling'
  end
end
