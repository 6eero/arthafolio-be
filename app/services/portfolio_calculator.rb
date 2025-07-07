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
      crypto: crypto_total.to_f.round(2),
      etf: etf_total.to_f.round(2),
      total: grand_total.to_f.round(2)
    }
  end

  private

  def build_assets
    return [] if grand_total.zero?

    @holdings.map do |h|
      quantity = h.quantity.to_f
      price = price_for(h).to_f.round(2)
      value = (quantity * price).to_f.round(2)
      percentage = grand_total.positive? ? (100.0 * value / grand_total).round(2) : 0

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

  def price_for(holding)
    latest_prices[holding.label] || 0
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
      .sum { |h| h.quantity.to_f * price_for(h) }
  end

  def latest_prices
    @latest_prices ||= begin
      crypto_labels = @holdings.select { |h| h.category == 'crypto' }.map(&:label).uniq
      etf_labels = @holdings.select { |h| h.category == 'etf' }.map(&:label).uniq

      crypto_prices = {}
      if crypto_labels.any?
        begin
          crypto_prices = CoinMarketCapFetcher.new.fetch_prices(crypto_labels) || {}
          Rails.logger.info "🟢 PortfolioCalculator.latest_prices - crypto_prices #{crypto_prices}"
        rescue StandardError => e
          Rails.logger.error "CMC fetch error: #{e.class} - #{e.message}"
        end
      end

      # Recupera i prezzi ETF dal database locale (Price model)
      etf_prices = {}
      etf_prices = Price.where(label: etf_labels).pluck(:label, :price).to_h if etf_labels.any?

      crypto_prices.merge(etf_prices) # unisce entrambi
    end
  end
end
