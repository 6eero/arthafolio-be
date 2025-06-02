class HoldingsController < ApplicationController
  def index
    holdings = Holding.all
    
    crypto_holdings = holdings.filter { |h| h.category == 0 }
    crypto_symbols = crypto_holdings.map(&:label).uniq
    crypto_prices = CoinMarketCapFetcher.new.fetch_prices(crypto_symbols)

    assets = holdings.map do |h|
    price = h.category == 1 ? 1 : (crypto_prices[h.label] || 0)

    {
      label: h.label,
      quantity: h.quantity.to_f,
      price: price,
      value: h.quantity.to_f * price,
    }
  end


    crypto_total = holdings.select { |h| h.category == 0 }.sum { |h| h.quantity.to_f * (crypto_prices[h.label] || 0) }

    liquidity_total = holdings.select { |h| h.category == 1 } .first&.quantity.to_f || 0.0

    totals = {
      total: crypto_total + liquidity_total,
      crypto: crypto_total,
      liquidity: liquidity_total
    }

    render json: { assets: assets, totals: totals }
  end
end


  
