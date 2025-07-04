# frozen_string_literal: true

require 'httparty'

# This class fetches data from the CoinMarketCap API.
class CoinMarketCapFetcher
  include HTTParty
  base_uri 'https://pro-api.coinmarketcap.com/v1'

  def initialize
    @headers = {
      'X-CMC_PRO_API_KEY' => ENV.fetch('CMC_API_KEY', nil),
      'Accept' => 'application/json'
    }
  end

  # Accetta uno o più simboli (stringa singola o array) e restituisce un hash con i prezzi
  def fetch_prices(symbols)
    Rails.logger.info "📈 symbolss: #{symbols}"
    symbols = [symbols] if symbols.is_a?(String) # garantisce un array
    query_symbols = symbols.join(',')

    response = self.class.get(
      '/cryptocurrency/quotes/latest',
      headers: @headers,
      query: {
        symbol: query_symbols,
        convert: 'EUR'
      }
    )
    Rails.logger.info "🟢 response of CoinMarketCapFetcher.fetch_prices method: #{response}"

    return nil unless response.success?

    data = response.parsed_response['data']
    Rails.logger.info "🟢 parsed_response of CoinMarketCapFetcher.fetch_prices method: #{data}"

    # Legge e stampa i prezzi salvati nella tabella Price
    prices = Price.all
    prices.each do |price|
      Rails.logger.info "🟢 prices table BEFORE: Label: #{price.label}, Category: #{price.category}, Price: #{price.price}, Retrieved at: #{price.retrieved_at}"
    end

    # Costruisce l'hash dei prezzi risultanti
    result = symbols.each_with_object({}) do |symbol, hash|
      price = data.dig(symbol, 'quote', 'EUR', 'price')
      hash[symbol] = price
    end

    Rails.logger.info "🟢 Resulting prices hash: #{result}"

    # Aggiorna i prezzi nella tabella Price
    result.each do |label, new_price|
      price_record = Price.find_by(label: label)
      if price_record
        price_record.update(price: new_price, retrieved_at: Time.current)
        Rails.logger.info "✅ Updated price for #{label}: #{new_price}"
      else
        Rails.logger.warn "⚠️ No price record found for label: #{label}, skipping update."
      end
    end

    prices = Price.all
    prices.each do |price|
      Rails.logger.info "🟢 prices table AFTER: Label: #{price.label}, Category: #{price.category}, Price: #{price.price}, Retrieved at: #{price.retrieved_at}"
    end

    result
  end
end
