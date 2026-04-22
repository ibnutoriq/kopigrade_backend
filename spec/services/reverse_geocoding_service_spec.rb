require "rails_helper"

RSpec.describe ReverseGeocodingService do
  # Glenmore: lat -8.30..-8.18, lon 114.03..114.18
  # Kalibaru: lat -8.36..-8.24, lon 113.97..114.10
  # (-8.20, 114.12) is inside Glenmore but NOT inside Kalibaru
  describe ".lookup" do
    it "returns Glenmore for a coordinate uniquely inside Glenmore" do
      expect(described_class.lookup(-8.20, 114.12)).to eq("Glenmore")
    end

    it "returns Kalibaru for a coordinate inside Kalibaru" do
      expect(described_class.lookup(-8.33, 114.03)).to eq("Kalibaru")
    end

    it "returns the fallback for coordinates outside all Banyuwangi boxes" do
      expect(described_class.lookup(-6.0, 106.0)).to eq(ReverseGeocodingService::FALLBACK)
    end

    it "handles string coordinates" do
      expect(described_class.lookup("-8.20", "114.12")).to eq("Glenmore")
    end
  end
end
