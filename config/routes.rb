# config/routes.rb
Rails.application.routes.draw do
  get '/health', to: 'health#show'

  # Namespace per le API
  namespace :api do
    post 'login', to: 'sessions#login'
    post 'refresh', to: 'refresh#create'
    delete 'logout', to: 'sessions#logout'
    get 'who_am_i', to: 'users#who_am_i'

    get 'holdings', to: 'holdings#index'
  end
end
