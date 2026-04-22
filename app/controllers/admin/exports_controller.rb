require "csv"

class Admin::ExportsController < Admin::BaseController
  def scan_results
    headers["Content-Disposition"] = "attachment; filename=\"scan_results_#{Date.current}.csv\""
    headers["Content-Type"] ||= "text/csv"
    headers["X-Accel-Buffering"] = "no"
    headers.delete("Content-Length")

    self.response_body = scan_results_csv_enumerator
  end

  private

  def scan_results_csv_enumerator
    Enumerator.new do |yielder|
      yielder << CSV.generate_line(%w[
        id created_at device_id sub_district variety
        total_beans black_defects broken_defects
        sni_defect_value sni_grade export_eligible status
      ])

      ScanResult.order(:id).find_each do |scan|
        yielder << CSV.generate_line([
          scan.id,
          scan.created_at&.iso8601,
          scan.device_id,
          scan.sub_district,
          scan.variety,
          scan.total_beans,
          scan.black_defects,
          scan.broken_defects,
          scan.sni_defect_value,
          scan.sni_grade,
          scan.export_eligible,
          scan.status
        ])
      end
    end
  end
end
