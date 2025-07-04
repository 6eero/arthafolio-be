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
    Rails.logger.info "🟢 CoinMarketCapFetcher.fetch_prices - Arguments: #{symbols}"
    symbols = [symbols] if symbols.is_a?(String) # garantisce un array
    query_symbols = symbols.join(',')

    # Controlla se serve aggiornare: almeno un record è più vecchio di 5 minuti?
    outdated_prices = Price.where(label: symbols).where(retrieved_at: ...5.minutes.ago)
    if outdated_prices.empty?
      Rails.logger.info '🟢 CoinMarketCapFetcher.fetch_prices - Tutti i prezzi sono aggiornati. Nessuna chiamata API effettuata.'

      # Costruisce e restituisce l'hash corrente dei prezzi
      result = symbols.each_with_object({}) do |symbol, hash|
        price_record = Price.find_by(label: symbol)
        hash[symbol] = price_record&.price
      end

      Rails.logger.info "🟢 CoinMarketCapFetcher.fetch_prices - Returning cached prices hash: #{result}"
      return result
    end

    # ⬇️ Se almeno un prezzo è vecchio, allora si fa la chiamata
    response = self.class.get(
      '/cryptocurrency/quotes/latest',
      headers: @headers,
      query: {
        symbol: query_symbols,
        convert: 'EUR'
      }
    )
    Rails.logger.info "🟢 CoinMarketCapFetcher.fetch_prices - Full response: #{response}"

    return nil unless response.success?

    data = response.parsed_response['data']

    # Stampa i prezzi correnti prima dell'aggiornamento
    Price.all.each do |price|
      Rails.logger.info "🟢 prices table BEFORE: Label: #{price.label}, Category: #{price.category}, Price: #{price.price}, Retrieved at: #{price.retrieved_at}"
    end

    # Costruisce l'hash dei prezzi ricevuti
    result = symbols.each_with_object({}) do |symbol, hash|
      price = data.dig(symbol, 'quote', 'EUR', 'price')
      hash[symbol] = price
    end

    Rails.logger.info "🟢 CoinMarketCapFetcher.fetch_prices - Parsed response #{result}"

    # Aggiorna la tabella Price
    result.each do |label, new_price|
      price_record = Price.find_by(label: label)
      if price_record
        price_record.update(price: new_price, retrieved_at: Time.current)
        Rails.logger.info "🟢 CoinMarketCapFetcher.fetch_prices - Updated price for #{label}: #{new_price}"
      else
        Price.create(label: label, price: new_price, retrieved_at: Time.current, category: 0)
        Rails.logger.info "🟢 CoinMarketCapFetcher.fetch_prices - Created new price record for #{label}: #{new_price}"
      end
    end

    result
  end
end
