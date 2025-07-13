FactoryBot.define do
  factory :price do
    label { 'BTC' }
    price { 20_000.0 }
    retrieved_at { 1.hour.ago }
  end
end
