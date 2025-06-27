# config/routes.rb
Rails.application.routes.draw do
  get 'api/holdings', to: 'holdings#index'

  # Namespace per le API
  namespace :api do
    post 'login', to: 'sessions#login'
    post 'refresh', to: 'refresh#create' 
    delete 'logout', to: 'sessions#logout'
    get  'who_am_i', to: 'users#who_am_i'
  end
end