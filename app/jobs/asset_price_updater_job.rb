# frozen_string_literal: true

# app/jobs/asset_price_updater_job.rb
class AssetPriceUpdaterJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info 'Starting asset price update job...'

    # 1. Raggruppa tutti gli asset unici per categoria.
    #    Il risultato sarà una Hash, es: { 'crypto' => [['BTC', 'crypto'], ...], 'etf' => [['ENUL.MI', 'etf']] }
    assets_by_category = Holding.distinct.pluck(:label, :category).group_by(&:second)

    # 2. Chiama metodi specifici per processare ogni categoria
    process_crypto_assets(assets_by_category['crypto'] || [])
    process_etf_assets(assets_by_category['etf'] || [])
    # Se in futuro aggiungerai altre categorie, basterà aggiungere una nuova riga qui

    Rails.logger.info 'Asset price update job finished.'
  end

  private

  # --- Processori Specifici per Categoria ---

  # Processa tutte le crypto in un unico batch
  def process_crypto_assets(crypto_assets)
    # Se non ci sono crypto, non fare nulla
    return if crypto_assets.empty?

    # Estrai solo i simboli (es. ['BTC', 'ETH', ...])
    crypto_symbols = crypto_assets.map(&:first)

    begin
      Rails.logger.info "Fetching batch prices for crypto: #{crypto_symbols.join(', ')}"
      # === LA VERA OTTIMIZZAZIONE È QUI ===
      # Esegui UNA SOLA chiamata API per tutte le crypto
      fetched_prices = CoinMarketCapFetcher.new.fetch_prices(crypto_symbols)

      # Ora itera sui prezzi ricevuti e aggiorna il database
      fetched_prices.each do |label, price|
        update_price_in_db(label, 'crypto', price)
      end
    rescue StandardError => e
      Rails.logger.error "Failed to fetch batch crypto prices: #{e.message}"
    end
  end

  # Processa gli ETF (che per natura sono individuali in questo caso)
  def process_etf_assets(etf_assets)
    return if etf_assets.empty?

    etf_assets.each do |label, category|
      Rails.logger.info "Fetching price for ETF: #{label}"
      price = PriceScraper.fetch_enul_price
      update_price_in_db(label, category, price)
    rescue StandardError => e
      # Se un singolo ETF fallisce, logga l'errore e continua con gli altri
      Rails.logger.error "Failed to fetch price for #{label}: #{e.message}"
    end
  end

  # --- Metodo Helper per il Database ---

  # Metodo centralizzato per aggiornare il prezzo, evitando duplicazione di codice
  def update_price_in_db(label, category, price)
    # Se per qualche motivo il prezzo non è valido, non fare nulla
    return unless price.is_a?(Numeric) && price.positive?

    # Trova o inizializza il record e aggiornalo
    price_record = Price.find_or_initialize_by(label: label)
    price_record.update!(
      category: category,
      price: price,
      retrieved_at: Time.current
    )
    Rails.logger.info "Updated price for #{label} [#{category}]: #{price}"
  end
end
