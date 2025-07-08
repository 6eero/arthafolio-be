# frozen_string_literal: true

module Api
  # Handles API requests related to user holdings and portfolio data.
  class HoldingsController < ApplicationController
    def index
      Rails.logger.info "Current user ID: #{current_user&.id}"
      holdings = current_user.holdings.to_a
      Rails.logger.info "Holdings count for user #{current_user&.id}: #{holdings.size}"
      portfolio = PortfolioCalculator.new(holdings)
      render json: { assets: portfolio.assets, totals: portfolio.totals }
    end

    def create
      holding = current_user.holdings.new(holding_params)

      if holding.save
        # Fetch price right after saving the holding
        fetch_and_store_price_for(holding)

        holdings = current_user.holdings
        portfolio = PortfolioCalculator.new(holdings)
        render json: { assets: portfolio.assets, totals: portfolio.totals }, status: :created
      else
        render json: { errors: holding.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      holding = find_holding

      unless holding
        render json: { error: 'Holding not found or not authorized' }, status: :not_found
        return
      end

      holding.destroy
      holdings = current_user.holdings
      portfolio = PortfolioCalculator.new(holdings)
      render json: { assets: portfolio.assets, totals: portfolio.totals }, status: :ok
    end

    def update
      holding = find_holding

      unless holding
        render json: { error: 'Holding not found or not authorized' }, status: :not_found
        return
      end

      if holding.update(holding_params)
        # (Opzionale) aggiorna anche il prezzo se serve
        fetch_and_store_price_for(holding) if holding.category == 'crypto'

        holdings = current_user.holdings
        portfolio = PortfolioCalculator.new(holdings)

        render json: {
          assets: portfolio.assets,
          totals: portfolio.totals
        }, status: :ok
      else
        render json: { errors: holding.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def find_holding
      current_user.holdings.find_by(label: params[:id])
    end

    def holding_params
      params.require(:holding).permit(%i[label quantity category])
    end

    # Fetches the latest price for a given holding (only if it's a crypto asset)
    # Queries the CoinMarketCap API only if necessary (smart caching).
    #
    # Creates a new Price with the holding field set to the given holding,
    # which correctly assigns the holding_id foreign key.
    def fetch_and_store_price_for(holding)
      return unless holding.category == 'crypto' # TODO: Manage other assets

      fetcher = CoinMarketCapFetcher.new
      prices = fetcher.fetch_prices(holding.label)

      return unless prices[holding.label].present?

      Price.create!(
        label: holding.label,
        price: prices[holding.label],
        category: holding.category,
        retrieved_at: Time.current,
        holding: holding
      )
    end
  end
end
