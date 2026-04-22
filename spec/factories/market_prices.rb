FactoryBot.define do
  factory :market_price do
    variety    { "robusta" }
    price      { 65_000 }
    sequence(:price_date) { |n| Date.current - n }
    source_url { "https://siskaperbapo.jatimprov.go.id/harga/tabel" }

    trait :arabika do
      variety { "arabika" }
      price   { 92_000 }
    end
  end
end
