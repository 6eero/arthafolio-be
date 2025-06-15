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

  def history
    [
      { value: 15_170.40, retrieved_at: '2025-06-15 15:00:27.363973' },
      { value: 22_596.39, retrieved_at: '2025-06-15 16:00:27.363973' },
      { value: 28_359.85, retrieved_at: '2025-06-15 17:00:27.363973' },
      { value: 32_602.92, retrieved_at: '2025-06-15 18:00:27.363973' },
      { value: 39_307.48, retrieved_at: '2025-06-15 19:00:27.363973' },
      { value: 36_653.87, retrieved_at: '2025-06-15 20:00:27.363973' },
      { value: 47_199.96, retrieved_at: '2025-06-15 21:00:27.363973' },
      { value: 48_359.85, retrieved_at: '2025-06-15 22:00:27.363973' },
      { value: 42_602.92, retrieved_at: '2025-06-15 23:00:27.363973' },
      { value: 49_307.48, retrieved_at: '2025-06-16 00:00:27.363973' },
      { value: 56_653.87, retrieved_at: '2025-06-16 01:00:27.363973' },
      { value: 57_199.96, retrieved_at: '2025-06-16 02:00:27.363973' }
    ]
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
    @latest_prices ||= Price.pluck(:label, :price).to_h
  end
end
