# frozen_string_literal: true

# Handles API requests related to user holdings and portfolio data.
class HoldingsController < ApplicationController
  def index
    holdings = Holding.all
    portfolio = PortfolioCalculator.new(holdings)
    render json: { assets: portfolio.assets, totals: portfolio.totals }
  end
end
