class PriceUpdater
  CACHE_DURATION = 5.minutes

  def self.update_all_stale_prices
    crypto_labels = Holding.where(category: 'crypto').distinct.pluck(:label)
    update_prices_from_api(crypto_labels)
  end

  def self.update_prices_from_api(labels)
    symbols_to_fetch = find_stale_symbols(labels)
    return if symbols_to_fetch.empty?

    fetcher = CoinMarketCapFetcher.new
    fetched_prices = fetcher.fetch_prices(symbols_to_fetch)

    # Usa `upsert_all` per un aggiornamento bulk efficiente
    records_to_upsert = fetched_prices.map do |label, price|
      {
        label: label,
        category: 'crypto', # Assumiamo crypto
        price: price,
        retrieved_at: Time.current
      }
    end

    return if records_to_upsert.empty?

    Price.upsert_all(records_to_upsert, unique_by: :label)
    Rails.logger.info "[💾 PriceUpdater] - Updated prices for: #{fetched_prices.keys.join(', ')}"
  end

  private

  # Determina quali simboli hanno bisogno di un aggiornamento
  def self.find_stale_symbols(labels)
    return [] if labels.empty?

    # Trova i prezzi esistenti e recenti per i label richiesti
    recent_prices = Price.where(label: labels)
                         .where('retrieved_at > ?', CACHE_DURATION.ago)
                         .pluck(:label)

    # I simboli da aggiornare sono quelli richiesti MENO quelli con un prezzo recente
    labels.uniq - recent_prices
  end
end