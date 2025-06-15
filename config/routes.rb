# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  get 'api/holdings', to: 'holdings#index'

  mount Sidekiq::Web => '/sidekiq'
end
