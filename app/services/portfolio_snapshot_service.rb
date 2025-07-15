class PortfolioSnapshotService
  def self.snapshot_for_all_users
    User.find_each do |user|
      new(user).snapshot
    end
  end

  def initialize(user)
    @user = user
  end

  def snapshot
    holdings = @user.holdings
    return if holdings.empty?

    labels = holdings.map(&:label).uniq
    prices_map = Price.where(label: labels).index_by(&:label)

    latest_prices = holdings.map do |h|
      latest_price_record = prices_map[h.label]

      next unless latest_price_record

      {
        label: h.label,
        category: h.category,
        quantity: h.quantity,
        price: latest_price_record.price.to_f,
        value: (h.quantity * latest_price_record.price).to_f
      }
    end.compact

    total_value = latest_prices.sum { |h| h[:value] }

    @user.portfolio_snapshots.create!(
      # holdings_data: latest_prices,
      total_value: total_value,
      taken_at: Time.current
    )
  end
end
