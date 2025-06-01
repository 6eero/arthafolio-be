class HoldingsController < ApplicationController
  def index
  holdings = Holding.all

  symbols = holdings.map(&:label).uniq
  
  prices = CoinMarketCapFetcher.new.fetch_prices(symbols)

  result = holdings.map do |h|
    {
      id: h.id,
      category: h.category,
      label: h.label,
      quantity: h.quantity.to_f,
      price: prices[h.label],
      value: h.quantity.to_f * prices[h.label].to_f,
      created_at: h.created_at,
      updated_at: h.updated_at
    }
  end

  render json: result
end

  def get_price
    prices = CoinMarketCapFetcher.new.fetch_prices(['BTC', 'ETH', 'SOL', 'DOT', 'CRO']) 
    render json: prices.map { |symbol, price| { symbol: symbol, price: price } }
  end
end
