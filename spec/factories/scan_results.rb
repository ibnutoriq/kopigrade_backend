FactoryBot.define do
  factory :scan_result do
    association :api_client
    device_id     { SecureRandom.uuid }
    total_beans   { 500 }
    black_defects { 5 }
    broken_defects { 10 }
    latitude      { -8.2191 }
    longitude     { 114.0112 }
    variety       { "robusta" }
    scanned_at    { Time.current }

    trait :analyzed do
      status { "analyzed" }
      advice { "Kopi Anda memiliki kualitas baik." }
    end

    trait :failed do
      status { "failed" }
      error_message { "Service unavailable" }
    end

    trait :arabika do
      variety { "arabika" }
    end
  end
end
