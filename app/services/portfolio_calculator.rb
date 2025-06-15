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
      price = price_for(h)
      value = (quantity * price).round(2)
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
    @latest_prices ||= Price.pluck(:label, :price).to_h
  end
end
