# db/migrate/xxxxxxxx_fix_user_table_for_has_secure_password.rb

class FixUserTableForHasSecurePassword < ActiveRecord::Migration[7.0]
  def change
    # Rimuoviamo la colonna usata da Devise
    remove_column :users, :encrypted_password, :string

    # Aggiungiamo la colonna richiesta da has_secure_password
    add_column :users, :password_digest, :string

    # Possiamo anche rimuovere le altre colonne di Devise se non le usi
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_column :users, :remember_created_at, :datetime
  end
end
