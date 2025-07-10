# Pulizia dati
User.destroy_all
Holding.destroy_all
Price.destroy_all

User.find_or_create_by!(email: 'cron@yourapp.com') do |u|
  u.password = SecureRandom.hex(16)
end
