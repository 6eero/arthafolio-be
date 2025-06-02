class HoldingsController < ApplicationController
  def index
    holdings = Holding.all
    symbols = holdings.map(&:label).uniq
    prices = CoinMarketCapFetcher.new.fetch_prices(symbols)

    assets =  holdings.map do |h|
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

    totals = {
      total: holdings.reduce(0) { |sum, h| sum + h.quantity.to_f * prices[h.label].to_f },
      crypto: holdings.select { |h| h.category == 0 }.reduce(0) { |sum, h| sum + h.quantity.to_f * prices[h.label].to_f },
      etf: 23543.35436 # todo
    }

    render json: { assets: assets, totals: totals }
  end

  def get_price
    prices = CoinMarketCapFetcher.new.fetch_prices(['BTC', 'ETH', 'SOL', 'DOT', 'CRO']) 
    render json: prices.map { |symbol, price| { symbol: symbol, price: price } }
  end
end


  
