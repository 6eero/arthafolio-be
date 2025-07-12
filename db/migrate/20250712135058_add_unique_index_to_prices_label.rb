class AddUniqueIndexToPricesLabel < ActiveRecord::Migration[8.0]
  def change
    add_index :prices, :label, unique: true
  end
end
