class GeminiAdvisorJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(scan_result_id)
    scan = ScanResult.find(scan_result_id)
    return if scan.analyzed?

    if scan.sub_district.blank? && scan.latitude.present? && scan.longitude.present?
      scan.update_column(:sub_district, ReverseGeocodingService.lookup(scan.latitude, scan.longitude))
    end

    result = GeminiAdvisorService.new(scan).call

    if result.success?
      scan.update!(advice: result.advice, status: :analyzed)
    else
      scan.update!(status: :failed, error_message: "GeminiAdvisorService returned no advice")
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("GeminiAdvisorJob: ScanResult ##{scan_result_id} not found — skipping")
  end
end
