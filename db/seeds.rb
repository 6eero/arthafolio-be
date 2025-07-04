# Pulisce i dati esistenti (solo per sviluppo)
User.destroy_all
Holding.destroy_all
Price.destroy_all
PortfolioSnapshot.destroy_all

user1 = User.create!(
  email: 'alice@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  refresh_token: SecureRandom.hex(16)
)
user2 = User.create!(
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
Holding.create!(holdings)

prices = [
  { category: 0, label: 'BTC', price: 65_000.00, retrieved_at: Time.current },
  { category: 0, label: 'ETH', price: 3500.00, retrieved_at: Time.current },
  { category: 0, label: 'SOL', price: 120.00, retrieved_at: Time.current },
  { category: 0, label: 'DOT', price: 35.00, retrieved_at: Time.current },
  { category: 1, label: 'ENUL.DE', price: 85.00, retrieved_at: Time.current }
]
Price.create!(prices)

PortfolioSnapshot.create!([
                            { value: 75_000.00 },
                            { value: 78_000.00 },
                            { value: 81_000.00 }
                          ])
