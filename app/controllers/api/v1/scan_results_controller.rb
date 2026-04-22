class Api::V1::ScanResultsController < Api::V1::BaseController
  def create
    scan = ScanResult.new(scan_result_params)
    scan.api_client = Current.api_client
    scan.save!

    GeminiAdvisorJob.perform_later(scan.id)

    render json: serialize_scan(scan, include_advice: false), status: :accepted
  end

  def show
    scan = ScanResult.find_by!(public_token: params[:id])
    render json: serialize_scan(scan, include_advice: true)
  end

  private

  def scan_result_params
    params.require(:scan_result).permit(
      :device_id, :total_beans, :black_defects, :broken_defects,
      :latitude, :longitude, :variety, :scanned_at
    )
  end

  def serialize_scan(scan, include_advice:)
    data = {
      id:                    scan.id,
      status:                scan.status,
      device_id:             scan.device_id,
      variety:               scan.variety,
      total_beans:           scan.total_beans,
      black_defects:         scan.black_defects,
      broken_defects:        scan.broken_defects,
      defect_rate:           scan.defect_rate.round(2),
      sni_defect_value:      scan.sni_defect_value,
      sni_grade:             scan.sni_grade,
      sni_grade_label:       scan.sni_grade_label,
      export_eligible:       scan.export_eligible,
      partial_coverage_notice: t("api.scan_results.partial_coverage_notice"),
      sub_district:          scan.sub_district,
      latitude:              scan.latitude,
      longitude:             scan.longitude,
      scanned_at:            scan.scanned_at,
      created_at:            scan.created_at,
      polling_url:           api_v1_scan_result_url(scan)
    }
    data[:advice] = scan.advice if include_advice
    data
  end
end
