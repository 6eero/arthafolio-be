module Api
  class HoldingsController < ApplicationController
    def index
      holdings = current_user.holdings.to_a
      portfolio = PortfolioCalculator.new(holdings, current_user)
      render json: { assets: portfolio.assets, totals: portfolio.totals, history: portfolio.history }
    end

    def create
      holding = current_user.holdings.new(holding_params)

      if holding.save
        PriceUpdater.update_prices_from_api([holding.label])

        holdings = current_user.holdings
        portfolio = PortfolioCalculator.new(holdings)
        render json: { assets: portfolio.assets, totals: portfolio.totals }, status: :created
      else
        render json: { errors: holding.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      holding = find_holding

      unless holding
        render json: { error: 'Holding not found or not authorized' }, status: :not_found
        return
      end

      if holding.update(holding_params)
        holdings = current_user.holdings
        portfolio = PortfolioCalculator.new(holdings)
        render json: { assets: portfolio.assets, totals: portfolio.totals }, status: :ok
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

    private

    def find_holding
      current_user.holdings.find_by(label: params[:id])
    end

    def holding_params
      params.require(:holding).permit(:label, :quantity, :category)
    end
  end
end
