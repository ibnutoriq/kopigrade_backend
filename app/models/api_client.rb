class ApiClient < ApplicationRecord
  has_many :scan_results, dependent: :nullify

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  def self.generate_token
    plaintext = SecureRandom.hex(32)
    digest = Digest::SHA256.hexdigest(plaintext)
    [ plaintext, digest ]
  end

  def self.authenticate(plaintext_token)
    digest = Digest::SHA256.hexdigest(plaintext_token.to_s)
    find_by(token_digest: digest, active: true)
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end
end
