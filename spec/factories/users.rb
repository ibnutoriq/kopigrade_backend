FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    admin { false }

    trait :admin do
      admin { true }
    end
  end
end
