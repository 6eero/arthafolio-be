class Holding < ApplicationRecord
  # enum category: { crypto: 0, etf: 1 } # commentato per test

  CATEGORIES = { 0 => "crypto", 1 => "etf" }

  validates :label, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }

  def category_name
    CATEGORIES[category]
  end
end
