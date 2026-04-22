require "rails_helper"

RSpec.describe GeminiAdvisorJob, type: :job do
  let(:scan) { create(:scan_result) }

  describe "#perform" do
    context "when the service succeeds" do
      it "sets status to analyzed and persists advice" do
        result = GeminiAdvisorService::Result.new(advice: "Saran kopi.", "success?": true)
        fake_svc = instance_double(GeminiAdvisorService, call: result)
        allow(GeminiAdvisorService).to receive(:new).and_return(fake_svc)

        described_class.perform_now(scan.id)

        scan.reload
        expect(scan.status).to eq("analyzed")
        expect(scan.advice).to eq("Saran kopi.")
      end
    end

    context "when the service fails" do
      it "sets status to failed" do
        result = GeminiAdvisorService::Result.new(advice: nil, "success?": false)
        fake_svc = instance_double(GeminiAdvisorService, call: result)
        allow(GeminiAdvisorService).to receive(:new).and_return(fake_svc)

        described_class.perform_now(scan.id)

        scan.reload
        expect(scan.status).to eq("failed")
        expect(scan.error_message).to be_present
      end
    end

    context "when the scan_result does not exist" do
      it "does not raise" do
        expect { described_class.perform_now(999_999) }.not_to raise_error
      end
    end

    context "when sub_district is blank and coordinates are present" do
      it "resolves the sub_district before calling Gemini" do
        scan.update_columns(sub_district: nil, latitude: -8.20, longitude: 114.12)
        result = GeminiAdvisorService::Result.new(advice: "OK", "success?": true)
        fake_svc = instance_double(GeminiAdvisorService, call: result)
        allow(GeminiAdvisorService).to receive(:new).and_return(fake_svc)

        described_class.perform_now(scan.id)

        expect(scan.reload.sub_district).to eq("Glenmore")
      end
    end
  end
end
