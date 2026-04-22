require "rails_helper"

RSpec.describe "Web::Home", type: :request do
  describe "GET /" do
    it "returns 200" do
      get root_path, headers: web_headers
      expect(response).to have_http_status(:ok)
    end

    it "shows the primary CTA" do
      get root_path, headers: web_headers
      expect(response.body).to include("Mulai Cek Mutu Kopi")
    end

    context "when market prices exist" do
      before do
        create(:market_price, variety: "robusta", price: 65_000)
        create(:market_price, :arabika, price: 92_000)
      end

      it "displays prices on the home page" do
        get root_path, headers: web_headers
        expect(response.body).to include("Rp")
      end
    end

    context "when no scans this week" do
      before { ScanResult.delete_all }

      it "hides the social proof line" do
        get root_path, headers: web_headers
        expect(response.body).not_to include("kali dipakai petani minggu ini")
      end
    end

    context "when scans exist this week" do
      before { create(:scan_result) }

      it "shows the social proof line" do
        get root_path, headers: web_headers
        expect(response.body).to include("kali dipakai petani minggu ini")
      end
    end
  end
end
