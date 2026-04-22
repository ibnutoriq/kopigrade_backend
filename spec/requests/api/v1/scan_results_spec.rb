require "rails_helper"

RSpec.describe "Api::V1::ScanResults", type: :request do
  let(:client)  { create(:api_client) }
  let(:headers) { bearer_headers(client) }

  let(:valid_params) do
    {
      scan_result: {
        device_id:      "device-rspec-1",
        total_beans:    500,
        black_defects:  20,
        broken_defects: 30,
        latitude:       -8.2191,
        longitude:      114.0112,
        variety:        "robusta",
        scanned_at:     "2026-04-22T08:30:00+07:00"
      }
    }
  end

  describe "POST /api/v1/scan_results" do
    it "returns 202 with SNI fields and enqueues GeminiAdvisorJob" do
      expect {
        post api_v1_scan_results_path, params: valid_params.to_json, headers: headers
      }.to have_enqueued_job(GeminiAdvisorJob)

      expect(response).to have_http_status(:accepted)
      body = JSON.parse(response.body)
      expect(body["id"]).to be_present
      expect(body["status"]).to eq("pending")
      expect(body["sni_defect_value"]).to be_present
      expect(body["sni_grade"]).to be_present
      expect(body["polling_url"]).to be_present
      expect(body["partial_coverage_notice"]).to be_present
    end

    it "returns 401 without Authorization header" do
      post api_v1_scan_results_path, params: valid_params.to_json,
           headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with an invalid token" do
      post api_v1_scan_results_path, params: valid_params.to_json,
           headers: { "Authorization" => "Bearer badtoken", "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 422 when total_beans is zero" do
      params = valid_params.deep_merge(scan_result: { total_beans: 0 })
      post api_v1_scan_results_path, params: params.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns 422 when latitude is outside Banyuwangi" do
      params = valid_params.deep_merge(scan_result: { latitude: -3.0 })
      post api_v1_scan_results_path, params: params.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/scan_results/:id" do
    it "returns the scan with advice when analyzed" do
      scan = create(:scan_result, :analyzed, api_client: client)
      get api_v1_scan_result_path(scan), headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(scan.id)
      expect(body["status"]).to eq("analyzed")
      expect(body["advice"]).to be_present
    end
  end
end
