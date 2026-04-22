require "rails_helper"

RSpec.describe "Web::Pages", type: :request do
  describe "GET /tentang" do
    it "returns 200" do
      get web_about_path, headers: web_headers
      expect(response).to have_http_status(:ok)
    end

    it "contains the partial-coverage caveat in Indonesian" do
      get web_about_path, headers: web_headers
      expect(response.body).to include("dua jenis cacat saja")
      expect(response.body).to include("estimasi")
    end
  end
end
