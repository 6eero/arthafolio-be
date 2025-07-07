# frozen_string_literal: true

module Api
  # Handles API requests related to user holdings and portfolio data.
  class HoldingsController < ApplicationController
    def index
      holdings = Holding.all
      portfolio = PortfolioCalculator.new(holdings)

      render json: { assets: portfolio.assets, totals: portfolio.totals, history: portfolio.history }
    end

    def create
      holding = Holding.new(holding_params)

      if holding.save
        # Fetch price right after saving the holding
        fetch_and_store_price_for(holding)

        holdings = Holding.all
        portfolio = PortfolioCalculator.new(holdings)
        render json: {
          assets: portfolio.assets,
          totals: portfolio.totals,
          history: portfolio.history
        }, status: :created
      else
        render json: { errors: holding.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      holding = Holding.find_by(label: params[:id])

      if holding
        holding.destroy
        holdings = Holding.all
        portfolio = PortfolioCalculator.new(holdings)
        render json: {
          assets: portfolio.assets,
          totals: portfolio.totals,
          history: portfolio.history
        }, status: :ok
      else
        render json: { error: 'Holding not found' }, status: :not_found
      end
    end

    private

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
