class CreateHoldings < ActiveRecord::Migration[8.0]
  def change
    create_table :holdings do |t|
      t.integer :category
      t.string :label
      t.decimal :quantity

      t.timestamps
    end
  end
end
