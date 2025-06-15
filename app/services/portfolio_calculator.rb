# frozen_string_literal: true

# app/services/portfolio_calculator.rb
class PortfolioCalculator
  # Inizializziamo l'oggetto con la collezione di holdings
  def initialize(holdings)
    @holdings = holdings
  end

  # Metodo pubblico per ottenere gli asset formattati
  def assets
    @assets ||= build_assets
  end

  # Metodo pubblico per ottenere i totali
  def totals
    {
      crypto: crypto_total,
      liquidity: liquidity_total,
      etf: etf_total,
      total: crypto_total + liquidity_total + etf_total
    }
  end

  private

  # Spostiamo qui la logica di costruzione degli asset
  def build_assets
    @holdings.map do |h|
      price = case h.category
              when 'liquidity' then 1
              when 'crypto' then crypto_prices[h.label] || 0
              when 'etf' then etf_price || 0
              else 0
              end

      value = h.quantity.to_f * price

      {
        label: h.label,
        quantity: h.quantity.to_f,
        price: price,
        value: value,
        category: h.category,
        percentage: (100.0 * value / (crypto_total + liquidity_total + etf_total)).round(2)
      }
    end
  end

  # Spostiamo qui i calcoli dei totali
  def crypto_total
    @crypto_total ||= calculate_total_for_category('crypto', crypto_prices)
  end

  def liquidity_total
    @liquidity_total ||= @holdings.select(&:liquidity?).sum { |h| h.quantity.to_f * 1 }
  end

  def etf_total
    @etf_total ||= calculate_total_for_category('etf', { default: etf_price })
  end

  def calculate_total_for_category(category, prices)
    @holdings
      .select { |h| h.category == category }
      .sum { |h| h.quantity.to_f * (prices[h.label] || prices[:default] || 0) }
  end

  # Logica per recuperare i prezzi
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
      PriceScraper.fetch_enul_price
    rescue StandardError => e
      Rails.logger.error "PriceScraper Error: #{e.message}"
      nil
    end
  end
end
