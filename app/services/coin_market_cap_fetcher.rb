require 'httparty'

class CoinMarketCapFetcher
  include HTTParty
  base_uri 'https://pro-api.coinmarketcap.com/v1'

  def initialize
    @headers = {
      'X-CMC_PRO_API_KEY' => ENV['CMC_API_KEY'], # ✅ carica l'API key da variabili d'ambiente
      'Accept' => 'application/json'
    }
  end

  def fetch_price(symbol = 'BTC')
    response = self.class.get(
      '/cryptocurrency/quotes/latest',
      headers: @headers,
      query: {
        symbol: symbol,
        convert: 'USD'
      }
    )

    return nil unless response.success?

    data = response.parsed_response["data"][symbol]
    data["quote"]["USD"]["price"]
  end
end
