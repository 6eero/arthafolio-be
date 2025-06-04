# frozen_string_literal: true

Rails.application.routes.draw do
  get 'api/holdings', to: 'holdings#index'
  get 'api/enul_price', to: 'holdings#show'
end
