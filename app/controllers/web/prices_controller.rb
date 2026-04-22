class Web::PricesController < Web::BaseController
  def index
    @robusta_price = MarketPrice.latest_for("robusta")
    @arabika_price = MarketPrice.latest_for("arabika")
  end
end
