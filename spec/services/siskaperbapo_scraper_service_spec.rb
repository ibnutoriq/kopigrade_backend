require "rails_helper"

RSpec.describe SiskaperbapoScraperService do
  let(:sample_html) do
    <<~HTML
      <html><body>
        <table>
          <tbody>
            <tr><td>Kopi Robusta</td><td>Banyuwangi</td><td>65.000</td></tr>
            <tr><td>Kopi Arabika</td><td>Banyuwangi</td><td>92.000</td></tr>
          </tbody>
        </table>
      </body></html>
    HTML
  end

  before do
    stub_request(:get, described_class::BASE_URL)
      .to_return(status: 200, body: sample_html, headers: { "Content-Type" => "text/html" })
  end

  describe "#call" do
    it "returns robusta and arabika prices" do
      results = described_class.new.call
      varieties = results.map { |r| r[:variety] }
      expect(varieties).to include("robusta", "arabika")
    end

    it "parses the numeric price correctly" do
      results = described_class.new.call
      robusta = results.find { |r| r[:variety] == "robusta" }
      expect(robusta[:price]).to eq(65_000)
    end

    it "raises on HTTP error" do
      stub_request(:get, described_class::BASE_URL).to_return(status: 503)
      expect { described_class.new.call }.to raise_error(RuntimeError, /HTTP 503/)
    end

    it "raises on network timeout" do
      stub_request(:get, described_class::BASE_URL).to_timeout
      expect { described_class.new.call }.to raise_error(RuntimeError, /unreachable/)
    end
  end
end
