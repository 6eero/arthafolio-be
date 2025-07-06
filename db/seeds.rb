# Pulizia dati
User.destroy_all
Holding.destroy_all
Price.destroy_all
PortfolioSnapshot.destroy_all

User.create!(
  email: 'alice@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  refresh_token: SecureRandom.hex(16)
)
User.create!(
  email: 'bob@example.com',
  password: 'securepass',
  password_confirmation: 'securepass',
  refresh_token: SecureRandom.hex(16)
)

holdings = [
  { category: 0, label: 'BTC', quantity: 0.75 },
  { category: 0, label: 'ETH', quantity: 3.5 },
  { category: 0, label: 'SOL', quantity: 50 },
  { category: 0, label: 'DOT', quantity: 80 },
  { category: 1, label: 'ENUL.DE', quantity: 20 }
]

created_holdings = holdings.map do |h|
  Holding.create!(h)
end

# Creo prezzi collegandoli ai rispettivi holding usando label come riferimento
prices_data = [
  { label: 'BTC', price: 65_000.00, retrieved_at: Time.current },
  { label: 'ETH', price: 3500.00, retrieved_at: Time.current },
  { label: 'SOL', price: 120.00, retrieved_at: Time.current },
  { label: 'DOT', price: 35.00, retrieved_at: Time.current },
  { label: 'ENUL.DE', price: 85.00, retrieved_at: Time.current }
]

prices_data.each do |p|
  holding = created_holdings.find { |h| h.label == p[:label] }
  Price.create!(price: p[:price], retrieved_at: p[:retrieved_at], holding: holding)
end

PortfolioSnapshot.create!([
                            { value: 75_000.00 },
                            { value: 78_000.00 },
                            { value: 81_000.00 }
                          ])
