Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # User authentication
      post 'signup', to: 'users#create'
      post 'login', to: 'sessions#create'
      delete 'logout', to: 'sessions#destroy'
      
      # User resources
      resources :users, only: [:show, :update, :destroy]
      
      # Calendar resources
      resources :calendars do
        # Schedules nested under calendars
        resources :schedules
      end
      
      # Direct access to schedules for the current user
      resources :schedules, only: [:index, :show, :update, :destroy]
    end
  end
end
