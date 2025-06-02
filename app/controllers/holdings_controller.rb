class HoldingsController < ApplicationController
  def index
    holdings = Holding.all
    
    crypto_holdings = holdings.filter { |h| h.category == 0 }
    crypto_symbols = crypto_holdings.map(&:label).uniq
    crypto_prices = CoinMarketCapFetcher.new.fetch_prices(crypto_symbols)

    assets = holdings.map do |h|
    price = h.category == 1 ? 1 : (crypto_prices[h.label] || 0)

    {
      id: h.id,
      category: h.category,
      label: h.label,
      quantity: h.quantity.to_f,
      price: price,
      value: h.quantity.to_f * price,
      created_at: h.created_at,
      updated_at: h.updated_at
    }
  end


    totals = {
      total: holdings.reduce(0) { |sum, h| sum + h.quantity.to_f * (crypto_prices[h.label] || 0 || 0) },
      crypto: holdings.select { |h| h.category == 0 }.reduce(0) { |sum, h| sum + h.quantity.to_f * (crypto_prices[h.label] || 0 || 0) },
      liquidity: holdings.select { |h| h.category == 1 }.first[:value].to_f
    }

    render json: { assets: assets, totals: totals }
  end

  def get_price
    prices = CoinMarketCapFetcher.new.fetch_prices(['BTC', 'ETH', 'SOL', 'DOT', 'CRO']) 
    render json: prices.map { |symbol, price| { symbol: symbol, price: price } }
  end
end


  
