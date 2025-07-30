# frozen_string_literal: true

# config/routes.rb
Rails.application.routes.draw do
  get '/health', to: 'health#show'

  # Namespace per le API
  namespace :api do
    post 'login', to: 'sessions#login'
    delete 'logout', to: 'sessions#logout'

    post 'register', to: 'registrations#create'
    get 'confirm_email', to: 'registrations#confirm_email'

    post 'refresh', to: 'refresh#create'

    get 'who_am_i', to: 'users#who_am_i'
    patch 'user/update_preferences', to: 'users#update_preferences'

    post '/snapshots', to: 'snapshots#create'

    resources :holdings, only: %i[index create destroy update]

    post 'ai/chat', to: 'ai#chat'
  end
end
