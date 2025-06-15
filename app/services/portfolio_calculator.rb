# frozen_string_literal: true

# app/services/portfolio_calculator.rb
class PortfolioCalculator
  Asset = Struct.new(:label, :quantity, :price, :value, :category, :percentage, keyword_init: true)

  def initialize(holdings)
    @holdings = holdings
  end

  def assets
    @assets ||= build_assets
  end

  def totals
    {
      crypto: crypto_total.round(2),
      etf: etf_total.round(2),
      total: grand_total.round(2)
    }
  end

  private

  def build_assets
    return [] if grand_total.zero?

    @holdings.map do |h|
      quantity = h.quantity.to_f
      price = fetch_price_for(h)
      value = (quantity * price).round(2)
      percentage = (100.0 * value / grand_total).round(2)

      Asset.new(
        label: h.label,
        quantity: quantity.round(5),
        price: price.round(5),
        value: value,
        category: h.category,
        percentage: percentage
      )
    end
  end

  def fetch_price_for(holding)
    case holding.category
    when 'crypto' then crypto_prices[holding.label] || 0
    when 'etf' then etf_price || 0
    else 0
    end
  end

  def grand_total
    @grand_total ||= crypto_total + etf_total
  end

  def crypto_total
    @crypto_total ||= calculate_total_for_category('crypto')
  end

  def etf_total
    @etf_total ||= calculate_total_for_category('etf')
  end

  def calculate_total_for_category(category)
    @holdings
      .select { |h| h.category == category }
      .sum { |h| h.quantity.to_f * fetch_price_for(h) }
  end

  def crypto_prices
    @crypto_prices ||= begin
      crypto_symbols = @holdings.select(&:crypto?).map(&:label).uniq
      CoinMarketCapFetcher.new.fetch_prices(crypto_symbols)
    rescue StandardError => e
      Rails.logger.error "CoinMarketCap API Error: #{e.message}"
      {}
    end
  end

  def etf_price
    @etf_price ||= begin
      Rails.logger.info 'Fetching ETF price via PriceScraper'
      price = PriceScraper.fetch_enul_price
      Rails.logger.info "Fetched ETF price: #{price}"
      price
    rescue StandardError => e
      Rails.logger.error "PriceScraper Error: #{e.class} - #{e.message}"
      nil
    end
  end
end
