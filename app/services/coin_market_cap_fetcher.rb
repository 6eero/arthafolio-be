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

  # Fetches the latest prices for the given symbols from the CoinMarketCap API.
  # Does NOT persist anything to the database — it only returns the data.
  #
  # Accepts a string or an array of symbols (e.g., 'BTC' or ['BTC', 'ETH']).
  # Returns a hash with the format: { 'BTC' => 60000.5, 'ETH' => 3000.2 }
  #
  # Example usage:
  #   fetcher.fetch_prices(['BTC', 'ETH'])
  #   => { "BTC" => 100436.17, "ETH" => 2509.95 }
  #
  #   fetcher.fetch_prices('BTC')
  #   => { "BTC" => 100456.55 }
  def fetch_prices(symbols)
    symbols_array = Array(symbols).uniq
    return {} if symbols_array.empty?

    response = self.class.get(
      '/cryptocurrency/quotes/latest',
      headers: @headers,
      query: { symbol: symbols_array.join(','), convert: 'EUR' }
    )

    return {} unless response.success?

    data = response.parsed_response['data']
    symbols_array.each_with_object({}) do |symbol, hash|
      price = data.dig(symbol, 'quote', 'EUR', 'price')
      hash[symbol] = price if price
    end
  end
end