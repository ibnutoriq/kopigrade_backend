require "rails_helper"

RSpec.describe "Web::Prices", type: :request do
  describe "GET /harga" do
    it "returns 200" do
      get web_prices_path, headers: web_headers
      expect(response).to have_http_status(:ok)
    end

    context "when prices exist for both varieties" do
      before do
        create(:market_price, variety: "robusta", price: 65_000)
        create(:market_price, :arabika, price: 92_000)
      end

      it "shows prices for both varieties" do
        get web_prices_path, headers: web_headers
        expect(response.body).to include("Robusta")
        expect(response.body).to include("Arabika")
        expect(response.body).to include("Rp")
      end
    end

    context "when no prices exist" do
      it "shows the no-price fallback" do
        get web_prices_path, headers: web_headers
        expect(response.body).to include("Harga belum tersedia hari ini")
      end
    end
  end
end
