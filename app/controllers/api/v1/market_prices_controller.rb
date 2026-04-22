class Api::V1::MarketPricesController < Api::V1::BaseController
  def index
    variety = params[:variety].presence&.downcase || "robusta"
    unless MarketPrice::VARIETIES.include?(variety)
      return render json: { error: t("api.market_prices.invalid_variety") }, status: :bad_request
    end

    price = if params[:date].present?
      MarketPrice.where(variety: variety, price_date: params[:date]).first
    else
      MarketPrice.latest_for(variety)
    end

    if price
      render json: {
        variety:    price.variety,
        price:      price.price,
        price_date: price.price_date,
        source_url: price.source_url
      }
    else
      render json: { error: t("api.market_prices.not_found", variety: variety) }, status: :not_found
    end
  end
end
