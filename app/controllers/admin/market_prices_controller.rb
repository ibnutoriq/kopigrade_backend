class Admin::MarketPricesController < Admin::BaseController
  before_action :set_market_price, only: [ :show, :edit, :update, :destroy ]

  def index
    @market_prices = MarketPrice.order(price_date: :desc, variety: :asc).limit(100)
  end

  def show; end

  def new
    @market_price = MarketPrice.new
  end

  def create
    @market_price = MarketPrice.new(market_price_params)
    if @market_price.save
      redirect_to admin_market_prices_path, notice: "Price saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @market_price.update(market_price_params)
      redirect_to admin_market_prices_path, notice: "Price updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @market_price.destroy
    redirect_to admin_market_prices_path, notice: "Price deleted."
  end

  def scrape_now
    PriceScraperJob.perform_later
    redirect_to admin_market_prices_path, notice: "Scrape job queued. Prices will update shortly."
  end

  private

  def set_market_price
    @market_price = MarketPrice.find(params[:id])
  end

  def market_price_params
    params.require(:market_price).permit(:variety, :price, :price_date, :source_url)
  end
end
