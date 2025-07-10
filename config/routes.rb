# frozen_string_literal: true

# config/routes.rb
Rails.application.routes.draw do
  get '/health', to: 'health#show'

  # Namespace per le API
  namespace :api do
    post 'login', to: 'sessions#login'
    post 'refresh', to: 'refresh#create'
    delete 'logout', to: 'sessions#logout'
    get 'who_am_i', to: 'users#who_am_i'

    post '/snapshots', to: 'snapshots#create'

    resources :holdings, only: %i[index create destroy update]
  end
end
