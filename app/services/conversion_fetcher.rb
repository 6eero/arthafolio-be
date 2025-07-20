class ConversionFetcher
  DEFAULT_RATE = 1.0 # eur

  SUPPORTED_RATES = {
    'usd' => 1.16
    # Others...
  }.freeze

  def self.fetch(currency)
    return DEFAULT_RATE if currency.blank?

    SUPPORTED_RATES.fetch(currency, DEFAULT_RATE)
  end
end
