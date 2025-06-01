class HoldingsController < ApplicationController
  def index
    holdings = Holding.all

    render json: holdings.map { |h|
      {
        id: h.id,
        category: h.category,
        label: h.label,
        quantity: h.quantity.to_f,
        created_at: h.created_at,
        updated_at: h.updated_at
      }
    }
  end

  def get_price
    prices = CoinMarketCapFetcher.new.fetch_prices(['BTC', 'ETH', 'SOL', 'DOT', 'CRO'])

    render json: prices.map { |symbol, price| { symbol: symbol, price: price } }
  end
end
