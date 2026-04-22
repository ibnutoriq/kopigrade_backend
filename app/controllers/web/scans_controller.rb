class Web::ScansController < Web::BaseController
  def new
    @scan = ScanResult.new(variety: "robusta")
    @sub_districts = ReverseGeocodingService.all_sub_districts
  end

  def create
    centroid = ReverseGeocodingService.centroid_for(scan_params[:sub_district])

    @scan = ScanResult.new(scan_params)
    @scan.scanned_at = Time.current

    if centroid
      @scan.latitude  = centroid[:latitude]
      @scan.longitude = centroid[:longitude]
    end

    if @scan.save
      GeminiAdvisorJob.perform_later(@scan.id)
      redirect_to web_scan_path(@scan)
    else
      @sub_districts = ReverseGeocodingService.all_sub_districts
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @scan = ScanResult.find(params[:id])
    @market_price = MarketPrice.latest_for(@scan.variety)
  end

  private

  def scan_params
    params.require(:scan_result).permit(:variety, :total_beans, :black_defects, :broken_defects, :sub_district)
  end
end
