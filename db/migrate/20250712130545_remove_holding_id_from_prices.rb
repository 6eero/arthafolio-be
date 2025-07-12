class RemoveHoldingIdFromPrices < ActiveRecord::Migration[8.0]
  def change
    remove_reference :prices, :holding, null: false, foreign_key: true
  end
end
