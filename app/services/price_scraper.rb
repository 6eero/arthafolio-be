# frozen_string_literal: true

require 'httparty'
require 'nokogiri'

# class to scrape price
class PriceScraper
  def self.fetch_enul_price
    url = 'https://finance.yahoo.com/quote/EUNL.DE/'

    response = HTTParty.get(url, headers: { 'User-Agent' => 'Mozilla/5.0' })
    doc = Nokogiri::HTML(response.body)

    # Cerca il prezzo all'interno del DOM
    price_element = doc.at_css('span[data-testid="qsp-price"]')

    raise 'Prezzo non trovato nella pagina' unless price_element

    price = price_element.text
    price.to_f
  end
end
