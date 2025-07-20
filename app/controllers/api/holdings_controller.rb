module Api
  # Api::HoldingsController is a RESTful API controller responsible for managing a
  # user's asset holdings. It supports creating, updating, retrieving, and deleting
  # holdings, and responds with updated portfolio data including:
  #
  # - Asset breakdown (with value, category, and percentage of portfolio)
  # - Total values for crypto, ETFs, and overall
  # - Historical portfolio value snapshots
  #
  # The controller delegates portfolio calculations to the PortfolioCalculator service
  # and integrates with PriceUpdater to fetch current prices upon creation.
  #
  # Endpoints:
  #   GET    /api/holdings      → List current holdings and portfolio summary
  #   POST   /api/holdings      → Create a new holding and return updated portfolio
  #   PATCH  /api/holdings/:id  → Update an existing holding
  #   DELETE /api/holdings/:id  → Remove a holding and return updated portfolio
  #
  # Authorization:
  # - All actions are scoped to the authenticated `current_user`
  # - Invalid or unauthorized requests return appropriate error responses
  #
  # Example response:
  # {
  #   assets: [...],
  #   totals: { crypto: 1200.0, etf: 800.0, total: 2000.0 },
  #   history: [{ total_value: 1980.0, taken_at: "2025-07-12T14:32:00Z" }, ...]
  # }
  class HoldingsController < ApplicationController
    def index
      render_portfolio
    end

    def create
      holding = current_user.holdings.new(holding_params)

      if holding.save
        PriceUpdater.update_prices_from_api([holding.label])
        render_portfolio(status: :created)
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
        render_portfolio(status: :ok)
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
      render_portfolio(status: :ok)
    end

    private

    def find_holding
      current_user.holdings.find_by(label: params[:id])
    end

    def holding_params
      params.require(:holding).permit(:label, :quantity, :category)
    end

    def render_portfolio(status: :ok)
      holdings = current_user.holdings.to_a
      timeframe = params[:timeframe] || 'D'
      currency = (current_user.preferred_currency || 'eur').downcase

      portfolio = PortfolioCalculator.new(holdings, current_user, timeframe, currency)

      render json: {
        assets: portfolio.assets,
        totals: portfolio.totals,
        history: portfolio.history
      }, status: status
    end
  end
end
