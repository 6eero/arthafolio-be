class CreatePortfolioSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolio_snapshots do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :holdings_data
      t.decimal :total_value
      t.datetime :taken_at

      t.timestamps
    end
  end
end
