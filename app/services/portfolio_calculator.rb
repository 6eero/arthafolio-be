class PortfolioCalculator
  Asset = Struct.new(:label, :quantity, :price, :value, :category, :percentage, keyword_init: true)

  def initialize(holdings, user)
    @holdings = holdings
    @user = user
  end

  def assets
    @assets ||= build_assets
  end

  def history
    snapshots = @user.portfolio_snapshots.order(created_at: :asc)

    snapshots.map do |snapshot|
      {
        total_value: snapshot.total_value.to_f,
        taken_at: snapshot.taken_at
      }
    end
  end

  def totals
    {
      crypto: crypto_total.to_f.round(2),
      etf: etf_total.to_f.round(2),
      total: grand_total.to_f.round(2)
    }
  end

  private

  def build_assets
    return [] if grand_total.zero?

    @holdings.map do |h|
      quantity = h.quantity.to_f
      price = latest_price_for(h.label).to_f.round(2)
      value = (quantity * price).to_f.round(2)
      percentage = grand_total.positive? ? (100.0 * value / grand_total).round(2) : 0

      Asset.new(
        label: h.label,
        quantity: quantity.round(5),
        price: price.round(5),
        value: value,
        category: h.category,
        percentage: percentage
      )
    end.sort_by { |a| -a.percentage }
  end

  def latest_price_for(label)
    @latest_prices ||= Price.where(label: @holdings.map(&:label).uniq)
                            .order(retrieved_at: :desc)
                            .group_by(&:label)
                            .transform_values(&:first)
    @latest_prices[label]&.price || 0
  end

  def grand_total
    @grand_total ||= crypto_total + etf_total
  end

  def crypto_total
    @crypto_total ||= calculate_total_for_category('crypto')
  end

  def etf_total
    @etf_total ||= calculate_total_for_category('etf')
  end

  def calculate_total_for_category(category)
    @holdings
      .select { |h| h.category == category }
      .sum { |h| h.quantity.to_f * latest_price_for(h.label) }
  end
end
