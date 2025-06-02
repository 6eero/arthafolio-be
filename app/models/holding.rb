class Holding < ApplicationRecord
  # enum category: { crypto: 0, liquidity: 1 } # commentato per test

  CATEGORIES = { 0 => "crypto", 1 => "liquidity" }

  validates :label, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }

  def category_name
    CATEGORIES[category]
  end
end
