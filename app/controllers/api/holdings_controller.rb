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

    private

    def holding_params
      params.require(:holding).permit(%i[label quantity category])
    end
  end
end
