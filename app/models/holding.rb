class Holding < ApplicationRecord
  enum :category, { crypto: 0, etf: 1 }
  belongs_to :user
end
