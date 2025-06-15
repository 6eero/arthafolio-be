# frozen_string_literal: true

# Represents a financial holding in a user's portfolio.
#
# Each holding belongs to a specific category, such as a cryptocurrency or an ETF.
# The `category` field is implemented as an enum.
class Holding < ApplicationRecord
  enum :category, { crypto: 0, etf: 1 }
end
