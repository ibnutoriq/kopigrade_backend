class MarketPrice < ApplicationRecord
  VARIETIES = %w[robusta arabika].freeze

  validates :variety, presence: true, inclusion: { in: VARIETIES }
  validates :price, presence: true, numericality: { greater_than: 0, message: "must be greater than 0" }
  validates :price_date, presence: true
  validates :variety, uniqueness: { scope: :price_date, message: "already has a price for this date" }

  scope :for_variety, ->(variety) { where(variety: variety) }

  def self.latest_for(variety)
    where(variety: variety).order(price_date: :desc).first
  end
end
