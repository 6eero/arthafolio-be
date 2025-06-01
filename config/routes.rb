Rails.application.routes.draw do
  get "api/holdings", to: "holdings#index"
  get 'api/prices/btc', to: 'holdings#btc_price'

end
