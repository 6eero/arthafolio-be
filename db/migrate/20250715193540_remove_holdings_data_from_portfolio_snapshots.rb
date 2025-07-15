class RemoveHoldingsDataFromPortfolioSnapshots < ActiveRecord::Migration[8.0]
  def change
    remove_column :portfolio_snapshots, :holdings_data, :jsonb
  end
end
