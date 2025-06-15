# frozen_string_literal: true

# app/jobs/create_portfolio_snapshot_job.rb
class CreatePortfolioSnapshotJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info 'Starting portfolio snapshot creation...'

    holdings = Holding.all
    portfolio = PortfolioCalculator.new(holdings)
    total_value = portfolio.totals[:total]

    # Create new record in the snapshot table
    if total_value.positive?
      PortfolioSnapshot.create!(value: total_value)
      Rails.logger.info "Successfully created portfolio snapshot with value: #{total_value}"
    else
      Rails.logger.warn 'Skipping snapshot creation due to zero or negative total value.'
    end
  rescue StandardError => e
    Rails.logger.error "Failed to create portfolio snapshot: #{e.message}"
  end
end
