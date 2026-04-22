class Admin::ScanResultsController < Admin::BaseController
  def index
    @scan_results = ScanResult.order(created_at: :desc)
    @scan_results = @scan_results.where(sub_district: params[:sub_district]) if params[:sub_district].present?
    @scan_results = @scan_results.where(status: params[:status]) if params[:status].present?
    @scan_results = @scan_results.where(sni_grade: params[:sni_grade]) if params[:sni_grade].present?
    if params[:from].present? && params[:to].present?
      @scan_results = @scan_results.where(created_at: params[:from]..params[:to])
    end
    @scan_results = @scan_results.page(params[:page]).per(25) if @scan_results.respond_to?(:page)
  end

  def show
    @scan_result = ScanResult.find(params[:id])
  end

  def destroy
    ScanResult.find(params[:id]).destroy
    redirect_to admin_scan_results_path, notice: "Scan result deleted."
  end
end
