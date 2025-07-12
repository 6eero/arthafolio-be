class AddUniqueIndexToPricesLabel < ActiveRecord::Migration[7.0]
  def change
    # Rimuovi eventuale indice non unico esistente su label (se presente)
    remove_index :prices, :label if index_exists?(:prices, :label) && !index_unique?(:prices, :label)

    # Aggiungi indice unico su label
    add_index :prices, :label, unique: true
  end

  private

  # Helper per verificare se un indice è unico
  def index_unique?(table, column)
    indexes(table).any? { |i| i.columns == Array(column).map(&:to_s) && i.unique }
  end
end
