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
    Rails.logger.info "[🟢 CoinMarketCapFetcher.fetch_prices] - Arguments: #{symbols}"
    symbols = [symbols] if symbols.is_a?(String)
    return {} if symbols.empty? # Evita chiamate inutili se non ci sono simboli

    query_symbols = symbols.uniq.join(',') # Usa uniq per evitare duplicati

    # 1. Controlla se qualche simbolo richiesto manca completamente dal nostro DB
    existing_price_labels = Price.where(label: symbols).pluck(:label)
    any_symbol_is_missing = (symbols.uniq - existing_price_labels).any?

    # 2. Controlla se i prezzi esistenti sono troppo vecchi
    outdated_prices_exist = Price.where(label: existing_price_labels).where(retrieved_at: ...5.minutes.ago).exists?

    # 3. Controlla se i prezzi esistenti non sono validi (nil o 0)
    wrong_price_exists = Price.where(label: existing_price_labels).where(price: [nil, 0]).exists?

    Rails.logger.info "[🔎 CoinMarketCapFetcher.fetch_prices] - Checks: Missing? #{any_symbol_is_missing}, Outdated? #{outdated_prices_exist}, Wrong? #{wrong_price_exists}"

    # Se NESSUN simbolo manca, NESSUN prezzo è vecchio e NESSUN prezzo è errato, allora usa la cache
    unless any_symbol_is_missing || outdated_prices_exist || wrong_price_exists
      result = Price.where(label: symbols).pluck(:label, :price).to_h
      Rails.logger.info "[🟠 CoinMarketCapFetcher.fetch_prices] - Prices already updated! No API call done: #{result}"
      return result
    end

    # ⬇️ Altrimenti, si fa la chiamata API
    response = self.class.get(
      '/cryptocurrency/quotes/latest',
      headers: @headers,
      query: {
        symbol: query_symbols,
        convert: 'EUR'
      }
    )
    Rails.logger.info "[🟢 CoinMarketCapFetcher.fetch_prices] - Full response: #{response.code}" # Logga solo il codice per pulizia

    return nil unless response.success?

    data = response.parsed_response['data']

    result = symbols.uniq.each_with_object({}) do |symbol, hash|
      price = data.dig(symbol, 'quote', 'EUR', 'price')
      hash[symbol] = price
    end

    Rails.logger.info "[🟢 CoinMarketCapFetcher.fetch_prices] - Parsed response #{result}"

    # Aggiorna la tabella Price
    result.each do |label, new_price|
      # Usa find_or_initialize_by per gestire sia la creazione che l'aggiornamento
      price_record = Price.find_or_initialize_by(label: label)

      # Aggiorna solo se il prezzo è valido
      if new_price.to_f > 0
        price_record.price = new_price
        price_record.retrieved_at = Time.current
        # Assumiamo che se arriva da CMC, la categoria sia 'crypto' (enum 0)
        price_record.category ||= 'crypto'
        price_record.save
        Rails.logger.info "[💾 CoinMarketCapFetcher.fetch_prices] - Saved price for #{label}: #{new_price}"
      else
        Rails.logger.warn "[⚠️ CoinMarketCapFetcher.fetch_prices] - Invalid price received for #{label}: #{new_price}"
      end
    end

    result
  end
end
