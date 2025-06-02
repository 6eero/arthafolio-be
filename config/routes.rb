Rails.application.routes.draw do
  get "api/holdings", to: "holdings#index"
  get 'api/prices', to: 'holdings#get_price'
end
