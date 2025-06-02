# frozen_string_literal: true

# Handles API requests related to user holdings and portfolio data.
class HoldingsController < ApplicationController
  def index
    holdings = Holding.all

    crypto_prices = fetch_crypto_prices(holdings)
    assets = build_assets(holdings, crypto_prices)
    totals = calculate_totals(holdings, crypto_prices)

    render json: { assets: assets, totals: totals }
  end

  private

  def fetch_crypto_prices(holdings)
    crypto_symbols = holdings.select { |h| h.category.zero? }.map(&:label).uniq
    CoinMarketCapFetcher.new.fetch_prices(crypto_symbols)
  end

  def build_assets(holdings, crypto_prices)
    holdings.map do |h|
      price = h.category == 1 ? 1 : (crypto_prices[h.label] || 0)

      {
        label: h.label,
        quantity: h.quantity.to_f,
        price: price,
        value: h.quantity.to_f * price
      }
    end
  end

  def calculate_totals(holdings, crypto_prices)
    crypto_total = calculate_crypto_total(holdings, crypto_prices)
    liquidity_total = calculate_liquidity_total(holdings)

    {
      total: crypto_total + liquidity_total,
      crypto: crypto_total,
      liquidity: liquidity_total
    }
  end

  def calculate_crypto_total(holdings, crypto_prices)
    holdings
      .select { |h| h.category.zero? }
      .sum { |h| h.quantity.to_f * (crypto_prices[h.label] || 0) }
  end

  def calculate_liquidity_total(holdings)
    holdings
      .select { |h| h.category == 1 }
      .first&.quantity.to_f || 0.0
  end
end
