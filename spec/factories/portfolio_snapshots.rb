FactoryBot.define do
  factory :portfolio_snapshot do
    association :user
    total_value { 10_000 }
    taken_at { Time.current }
  end
end
