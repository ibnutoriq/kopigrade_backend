require "rails_helper"

RSpec.describe "Api::V1::MarketPrices", type: :request do
  let(:client)  { create(:api_client) }
  let(:headers) { bearer_headers(client) }

  describe "GET /api/v1/market_prices" do
    context "when a robusta price exists" do
      before { create(:market_price) }

      it "returns the latest robusta price" do
        get api_v1_market_prices_path, headers: headers
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["variety"]).to eq("robusta")
        expect(body["price"]).to be_present
      end
    end

    context "when no price exists for the requested variety" do
      before { MarketPrice.where(variety: "arabika").delete_all }

      it "returns 404" do
        get api_v1_market_prices_path(variety: "arabika"), headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    it "returns 401 without Authorization header" do
      get api_v1_market_prices_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 400 for an invalid variety" do
      get api_v1_market_prices_path(variety: "liberica"), headers: headers
      expect(response).to have_http_status(:bad_request)
    end
  end
end
