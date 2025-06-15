# frozen_string_literal: true

# Handles API requests related to user holdings and portfolio data.
class HoldingsController < ApplicationController
  def index
    holdings = Holding.all
    portfolio = PortfolioCalculator.new(holdings)
    history = [
      { value: 15_170.40 },
      { value: 22_596.39 },
      { value: 28_359.85 },
      { value: 32_602.92 },
      { value: 39_307.48 },
      { value: 36_653.87 },
      { value: 47_199.96 },
      { value: 48_359.85 },
      { value: 42_602.92 },
      { value: 49_307.48 },
      { value: 56_653.87 },
      { value: 57_199.96 }
    ]
    render json: { assets: portfolio.assets, totals: portfolio.totals, history: history }
  end
end
