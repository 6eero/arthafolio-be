# Pulizia dati
User.destroy_all
Holding.destroy_all
Price.destroy_all

User.create!(
  email: 'alice@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  refresh_token: SecureRandom.hex(16)
)
