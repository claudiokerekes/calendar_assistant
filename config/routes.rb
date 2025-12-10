Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Root and main routes
  root "home#index"
  
  # Authentication routes
  get '/login', to: 'sessions#new'
  get '/auth/:provider/callback', to: 'sessions#omniauth'
  delete '/logout', to: 'sessions#destroy'
  get '/auth/failure', to: 'sessions#failure'
  
  # Dashboard routes
  get '/dashboard', to: 'dashboard#index'
  get '/dashboard/whatsapp', to: 'dashboard#whatsapp_numbers'
  
  # API routes
  namespace :api do
    namespace :v1 do
      # Calendar API
      resources :calendar, only: [] do
        collection do
          get :events
          post :events, action: :create_event
          get :availability
        end
        member do
          put '/', action: :update_event
          delete '/', action: :delete_event
        end
      end
      
      # Users API
      resources :users, only: [] do
        collection do
          get :profile
          put :profile, action: :update_profile
          get :whatsapp_numbers
          post :whatsapp_numbers, action: :create_whatsapp_number
          post :generate_api_token
        end
        member do
          put 'whatsapp_numbers/:whatsapp_id', action: :update_whatsapp_number
          delete 'whatsapp_numbers/:whatsapp_id', action: :delete_whatsapp_number
        end
      end
      
      # WhatsApp webhook
      post 'whatsapp/webhook/:phone_number', to: 'whatsapp#webhook'
      get 'whatsapp/webhook/:phone_number', to: 'whatsapp#verify_webhook'
    end
  end
end
