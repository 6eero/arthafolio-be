# frozen_string_literal: true

# Handles API requests related to user holdings and portfolio data.
class HoldingsController < ApplicationController
  def index
    holdings = Holding.all

    crypto_prices = fetch_crypto_prices(holdings)
    crypto_total = calculate_crypto_total(holdings, crypto_prices)

    etf_price = PriceScraper.fetch_enul_price

    assets = build_assets(holdings, crypto_prices, crypto_total)
    totals = calculate_totals(holdings, crypto_prices, etf_price)

    render json: { assets: assets, totals: totals }
  end

  private

  # Fetches current crypto prices for the given holdings using CoinMarketCap API.
  def fetch_crypto_prices(holdings)
    crypto_symbols = holdings.select { |h| h.category.zero? }.map(&:label).uniq
    CoinMarketCapFetcher.new.fetch_prices(crypto_symbols)
  end

  # Builds a list of asset hashes including label, quantity, price, value, category, and percentage.
  def build_assets(holdings, crypto_prices, crypto_total) # rubocop:disable Metrics/AbcSize
    holdings.map do |h|
      price = case h.category
              when 1 then 1 # liquidity
              when 0 then crypto_prices[h.label] || 0 # crypto
              else PriceScraper.fetch_enul_price # etf or other assets
              end

      value = h.quantity.to_f * price

      {
        label: h.label,
        quantity: h.quantity.to_f,
        price: price,
        value: value,
        category: h.category,
        percentage: h.category.zero? && crypto_total.positive? ? (100.0 * value / crypto_total).round(2) : 100
      }
    end
  end

  # Calculates total values for crypto, etf, liquidity, and the overall portfolio.
  def calculate_totals(holdings, crypto_prices, etf_price)
    crypto_total = calculate_crypto_total(holdings, crypto_prices)
    etf_total = calculate_etf_total(holdings, etf_price)
    liquidity_total = calculate_liquidity_total(holdings)

    {
      crypto: crypto_total,
      liquidity: liquidity_total,
      etf: etf_total,
      total: crypto_total + liquidity_total + etf_total
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

  def calculate_etf_total(holdings, etf_price)
    holdings
      .select { |h| h.category == 2 }
      .sum { |h| h.quantity.to_f * (etf_price || 0) }
  end
end
