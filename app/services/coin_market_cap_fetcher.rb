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

    return nil unless response.success?

    data = response.parsed_response['data']

    # Ritorna un hash tipo { 'BTC' => 68000.0, 'ETH' => 3800.0, ... }
    symbols.each_with_object({}) do |symbol, result|
      price = data.dig(symbol, 'quote', 'EUR', 'price')
      result[symbol] = price
    end
  end
end
