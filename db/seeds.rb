# Pulisce i dati esistenti (solo per sviluppo)
User.destroy_all
Holding.destroy_all
Price.destroy_all
PortfolioSnapshot.destroy_all

user1 = User.create!(
  email: "alice@example.com",
  password: "password123",
  password_confirmation: "password123",
  refresh_token: SecureRandom.hex(16)
)
user2 = User.create!(
  email: "bob@example.com",
  password: "securepass",
  password_confirmation: "securepass",
  refresh_token: SecureRandom.hex(16)
)

holdings = [
  { category: 0, label: "Bitcoin", quantity: 0.75 },
  { category: 0, label: "Ethereum", quantity: 3.5 },
  { category: 0, label: "Crypto.com Coin (CRO)", quantity: 1500 },
  { category: 0, label: "Solana", quantity: 50 },
  { category: 0, label: "Polkadot", quantity: 80 },
  { category: 1, label: "enul.de", quantity: 20 }
]
Holding.create!(holdings)

prices = [
  { category: 0, label: "Bitcoin", price: 65000.00, retrieved_at: Time.current },
  { category: 0, label: "Ethereum", price: 3500.00, retrieved_at: Time.current },
  { category: 0, label: "Crypto.com Coin (CRO)", price: 0.30, retrieved_at: Time.current },
  { category: 0, label: "Solana", price: 120.00, retrieved_at: Time.current },
  { category: 0, label: "Polkadot", price: 35.00, retrieved_at: Time.current },
  { category: 1, label: "enul.de", price: 85.00, retrieved_at: Time.current }
]
Price.create!(prices)

PortfolioSnapshot.create!([
  { value: 75000.00 },
  { value: 78000.00 },
  { value: 81000.00 }
])
