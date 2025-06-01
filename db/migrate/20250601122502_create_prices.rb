class CreatePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :prices do |t|
      t.integer :category
      t.string :label
      t.decimal :price
      t.datetime :retrieved_at

      t.timestamps
    end
  end
end
