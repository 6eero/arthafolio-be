# frozen_string_literal: true

Rails.application.routes.draw do
  get 'api/holdings', to: 'holdings#index'

  # Namespace per le API
  namespace :api do
    post 'login', to: 'sessions#login'

    # Dovrai creare anche l'endpoint per il refresh del token
    # che il tuo frontend si aspetta di chiamare
    post 'refresh', to: 'refresh#create'
  end
end
