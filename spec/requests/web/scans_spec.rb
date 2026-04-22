require "rails_helper"

RSpec.describe "Web::Scans", type: :request do
  let(:valid_params) do
    {
      scan_result: {
        variety:        "robusta",
        total_beans:    300,
        black_defects:  5,
        broken_defects: 10,
        sub_district:   "Glenmore"
      }
    }
  end

  describe "GET /scans/new" do
    it "returns 200 and renders the form" do
      get new_web_scan_path, headers: web_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cek Mutu Kopi Anda")
      expect(response.body).to include("Cek Mutu &amp; Saran")
    end
  end

  describe "POST /scans" do
    context "with valid params" do
      it "creates a ScanResult and redirects to show" do
        expect {
          post web_scans_path, params: valid_params, headers: web_headers
        }.to change(ScanResult, :count).by(1)

        expect(response).to redirect_to(web_scan_path(ScanResult.last))
      end

      it "enqueues GeminiAdvisorJob" do
        expect {
          post web_scans_path, params: valid_params, headers: web_headers
        }.to have_enqueued_job(GeminiAdvisorJob)
      end

      it "assigns latitude and longitude from sub-district centroid" do
        post web_scans_path, params: valid_params, headers: web_headers
        scan = ScanResult.last
        expect(scan.latitude).to be_present
        expect(scan.longitude).to be_present
      end
    end

    context "with invalid params — defects exceed total" do
      let(:bad_params) do
        {
          scan_result: {
            variety:        "robusta",
            total_beans:    100,
            black_defects:  80,
            broken_defects: 80,
            sub_district:   "Glenmore"
          }
        }
      end

      it "re-renders the form with 422" do
        post web_scans_path, params: bad_params, headers: web_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Mohon periksa kembali")
      end

      it "does not create a ScanResult" do
        expect {
          post web_scans_path, params: bad_params, headers: web_headers
        }.not_to change(ScanResult, :count)
      end
    end
  end

  describe "GET /scans/:id" do
    context "when scan is pending and within the 90-second window" do
      let(:scan) { create(:scan_result) }

      it "returns 200, shows spinner, and includes meta-refresh" do
        get web_scan_path(scan), headers: web_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sedang menganalisa")
        expect(response.body).to include('http-equiv="refresh"')
      end
    end

    context "when scan is pending and older than 90 seconds" do
      let(:scan) { create(:scan_result, created_at: 91.seconds.ago) }

      it "shows the timeout message without meta-refresh" do
        get web_scan_path(scan), headers: web_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Analisa lebih lama dari biasanya")
        expect(response.body).not_to include('http-equiv="refresh"')
      end
    end

    context "when scan is analyzed" do
      let(:scan) { create(:scan_result, :analyzed) }

      it "returns 200 and shows grade and advice" do
        get web_scan_path(scan), headers: web_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Estimasi Mutu SNI")
        expect(response.body).to include("Saran AI")
        expect(response.body).not_to include('http-equiv="refresh"')
      end

      context "with a market price for that variety" do
        before { create(:market_price, variety: scan.variety, price: 65_000) }

        it "shows the market price" do
          get web_scan_path(scan), headers: web_headers
          expect(response.body).to include("Harga pasar hari ini")
          expect(response.body).to include("Rp")
        end
      end

      context "without a market price" do
        it "shows the no-price fallback message" do
          get web_scan_path(scan), headers: web_headers
          expect(response.body).to include("Harga pasar belum tersedia hari ini")
        end
      end
    end

    context "when scan has failed" do
      let(:scan) { create(:scan_result, :failed) }

      it "shows a friendly error without leaking error_message" do
        get web_scan_path(scan), headers: web_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ada gangguan saat menyiapkan saran")
        expect(response.body).not_to include(scan.error_message)
      end
    end

    context "when scan does not exist" do
      it "returns 404" do
        get web_scan_path(id: 999_999), headers: web_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
