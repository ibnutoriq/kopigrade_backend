class Admin::DashboardController < Admin::BaseController
  def show
    now   = Time.current
    range = now.beginning_of_month..now.end_of_month

    @total_scans_mtd      = ScanResult.where(created_at: range).count
    @avg_defect_value_mtd = ScanResult.where(created_at: range).average(:sni_defect_value)&.round(1) || 0.0
    @unique_devices_mtd   = ScanResult.where(created_at: range).distinct.count(:device_id)

    export_count = ScanResult.where(created_at: range, export_eligible: true).count
    @export_eligible_pct  = @total_scans_mtd > 0 ? (export_count.to_f / @total_scans_mtd * 100).round(1) : 0.0

    @latest_robusta_price  = MarketPrice.latest_for("robusta")
    @latest_arabika_price  = MarketPrice.latest_for("arabika")

    @daily_scans           = ScanResult.group_by_day(:created_at, last: 30).count
    @defect_by_subdistrict = ScanResult.where.not(sub_district: nil)
                                       .group(:sub_district)
                                       .average(:sni_defect_value)
                                       .transform_values { |v| v&.round(1) || 0 }
                                       .sort_by { |_, v| -v }
                                       .first(10)
                                       .to_h
    @grade_distribution    = ScanResult.where(created_at: range)
                                       .where.not(sni_grade: nil)
                                       .group(:sni_grade)
                                       .count

    @latest_scans = ScanResult.order(created_at: :desc).limit(10)
  end
end
