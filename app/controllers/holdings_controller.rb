class HoldingsController < ApplicationController
  def index
  holdings = Holding.all

  # Prendo i simboli da label (crypto, ETF, ecc.)
  symbols = holdings.map(&:label).uniq

  # Prendo i prezzi per questi simboli
  prices = CoinMarketCapFetcher.new.fetch_prices(symbols)

  result = holdings.map do |h|
    {
      id: h.id,
      category: h.category,
      label: h.label,
      quantity: h.quantity.to_f,
      price: prices[h.label],  # usa label per cercare il prezzo
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
