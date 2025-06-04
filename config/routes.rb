# frozen_string_literal: true

Rails.application.routes.draw do
  get 'api/holdings', to: 'holdings#index'
end
