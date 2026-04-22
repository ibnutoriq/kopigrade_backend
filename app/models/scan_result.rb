class ScanResult < ApplicationRecord
  include SniGrading

  belongs_to :api_client, optional: true

  enum :status, { pending: "pending", analyzed: "analyzed", failed: "failed" }, default: "pending"
  enum :variety, { robusta: "robusta", arabika: "arabika" }, prefix: false

  VARIETIES = %w[robusta arabika].freeze
  BANYUWANGI_LAT_RANGE = (-9.0..-7.5).freeze
  BANYUWANGI_LON_RANGE = (113.5..115.0).freeze

  validates :total_beans, presence: true,
    numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10_000 }
  validates :black_defects, presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :broken_defects, presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :variety, inclusion: { in: VARIETIES }
  validate :defects_within_total_beans
  validate :coordinates_within_banyuwangi, if: -> { latitude.present? && longitude.present? }

  scope :this_month, -> { where(created_at: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :export_ready, -> { where(export_eligible: true) }

  private

  def defects_within_total_beans
    return unless total_beans && black_defects && broken_defects
    errors.add(:black_defects, :cannot_exceed_total) if black_defects > total_beans
    errors.add(:broken_defects, :cannot_exceed_total) if broken_defects > total_beans
    errors.add(:base, :defects_exceed_total) if black_defects + broken_defects > total_beans
  end

  def coordinates_within_banyuwangi
    errors.add(:latitude, :out_of_bounds) unless BANYUWANGI_LAT_RANGE.cover?(latitude.to_f)
    errors.add(:longitude, :out_of_bounds) unless BANYUWANGI_LON_RANGE.cover?(longitude.to_f)
  end
end
