class AddPrivacyAndCurrencyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :hide_holdings, :boolean, default: false
    add_column :users, :preferred_currency, :string, default: 'EUR'
  end
end
