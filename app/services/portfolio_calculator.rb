# PortfolioCalculator is a service class responsible for calculating portfolio-related
# data for a user. It operates on a collection of asset holdings and provides:
#
# - A list of assets with detailed metrics such as value, category, and percentage share.
# - Historical portfolio values based on user snapshots (limited to the most recent 20).
# - Totals for crypto, ETF, and combined asset values.
#
# This class is read-only and is designed to support portfolio summaries, analytics,
# or dashboards without persisting any state.
#
# Example usage:
#   calculator = PortfolioCalculator.new(user.holdings, user)
#   calculator.assets    # => [<Asset label: "BTC", value: 1000.0, ...>, ...]
#   calculator.history   # => [{ total_value: 1234.56, taken_at: <Time> }, ...]
#   calculator.totals    # => { crypto: 1000.0, etf: 500.0, total: 1500.0 }
#
# Note:
# - Asset prices are fetched from the most recent available data (Price model).
# - Percentages are relative to the total portfolio value.
class PortfolioCalculator
  Asset = Struct.new(:label, :quantity, :price, :value, :category, :percentage, keyword_init: true)

  def initialize(holdings, user, timeframe)
    @holdings = holdings
    @user = user
    @timeframe = timeframe
  end

  def assets
    @assets ||= build_assets
  end

  def history
    snapshots = @user.portfolio_snapshots.order(taken_at: :desc)

    grouped = case @timeframe&.upcase
              when 'H'
                snapshots.group_by { |s| s.taken_at.beginning_of_hour }
              when 'D', nil
                snapshots.group_by { |s| s.taken_at.to_date }
              when 'W'
                snapshots.group_by { |s| s.taken_at.beginning_of_week(:monday).to_date }
              when 'M'
                snapshots.group_by { |s| s.taken_at.beginning_of_month.to_date }
              else
                snapshots.group_by { |s| s.taken_at.to_date }
              end

    grouped.values.map(&:first)
           .sort_by(&:taken_at)
           .last(20)
           .map do |snapshot|
             {
               total_value: snapshot.total_value.to_f.round(2),
               taken_at: snapshot.taken_at
             }
           end
  end

  def totals
    current_total = crypto_total.to_f.round(2)
    yesterday_total = total_value_24h_ago

    pl_value = (current_total - yesterday_total).round(2)
    pl_percent = yesterday_total.positive? ? ((pl_value / yesterday_total) * 100).round(2) : 0

    {
      total: current_total,
      profit_loss_value: pl_value,
      profit_loss_percent: pl_percent
    }
  end

  private

  def build_assets
    return [] if crypto_total.zero?

    @holdings.map do |h|
      quantity = h.quantity.to_f
      price = latest_price_for(h.label).to_f.round(2)
      value = (quantity * price).to_f.round(2)
      percentage = crypto_total.positive? ? (100.0 * value / crypto_total).round(2) : 0

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

  def crypto_total
    @crypto_total ||= calculate_total_for_category('crypto')
  end

  def calculate_total_for_category(category)
    @holdings
      .select { |h| h.category == category }
      .sum { |h| h.quantity.to_f * latest_price_for(h.label) }
  end

  def total_value_24h_ago
    # Cerca lo snapshot più vicino a 24h fa, massimo con 1h di tolleranza
    target_time = 24.hours.ago

    snapshot = @user.portfolio_snapshots
                    .where('taken_at <= ?', target_time)
                    .order(taken_at: :desc)
                    .first

    snapshot&.total_value.to_f.round(2) || 0
  end
end
