class CreatePortfolioSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolio_snapshots do |t|
      t.decimal :value

      t.timestamps
    end
  end
end
