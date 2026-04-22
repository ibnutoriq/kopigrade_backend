class Web::HomeController < Web::BaseController
  def show
    @robusta_price = MarketPrice.latest_for("robusta")
    @arabika_price = MarketPrice.latest_for("arabika")
    @weekly_scan_count = ScanResult.where(created_at: 1.week.ago..Time.current).count
  end
end
