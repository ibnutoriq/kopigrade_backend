FactoryBot.define do
  factory :api_client do
    sequence(:name) { |n| "Flutter Client #{n}" }
    token_digest { Digest::SHA256.hexdigest(SecureRandom.hex(32)) }
    active { true }
  end
end
