class Holding < ApplicationRecord
  enum :category, { crypto: 0, etf: 1 }
  has_many :prices, dependent: :destroy
  belongs_to :user
end
