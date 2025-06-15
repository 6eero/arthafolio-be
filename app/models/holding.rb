# app/models/holding.rb
class Holding < ApplicationRecord
  # ... altre validazioni o associazioni ...

  # Usa enum per le categorie
  enum :category, { crypto: 0, liquidity: 1, etf: 2 }

  # Questo ti darà gratuitamente dei metodi helper come:
  # holding.crypto?
  # holding.liquidity?
  # holding.etf!
  # Holding.crypto # -> restituisce tutti gli holding di tipo crypto
end
