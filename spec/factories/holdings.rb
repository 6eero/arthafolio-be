FactoryBot.define do
  factory :holding do
    label { 'BTC' }
    quantity { 1.0 }
    category { 'crypto' }
    association :user
  end
end
