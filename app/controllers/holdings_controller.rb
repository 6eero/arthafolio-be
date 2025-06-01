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
    Rails.logger.info "Prices: #{prices.inspect}"  # prices: {"BTC"=>104283.64293003875, "ETH"=>2494.499933147048, "SOL"=>152.08263797451366, "DOT"=>4.026426879903671, "CRO"=>0.10285899614457555}
    render json: prices.map { |symbol, price| { symbol: symbol, price: price } }
  end
end
