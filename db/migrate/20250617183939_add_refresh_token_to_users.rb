# db/migrate/xxxxxxxxxxxxxx_add_refresh_token_to_users.rb

class AddRefreshTokenToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :refresh_token, :string
    # Aggiungere un indice su questa colonna può rendere più veloci le ricerche
    # del token durante il processo di refresh.
    add_index :users, :refresh_token, unique: true
  end
end
