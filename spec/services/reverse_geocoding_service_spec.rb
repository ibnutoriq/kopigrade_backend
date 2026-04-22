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

  describe ".all_sub_districts" do
    it "returns a sorted array of sub-district name strings" do
      names = described_class.all_sub_districts
      expect(names).to be_an(Array)
      expect(names).not_to be_empty
      expect(names).to eq(names.sort)
    end

    it "includes known sub-districts" do
      names = described_class.all_sub_districts
      expect(names).to include("Glenmore", "Kalibaru", "Banyuwangi")
    end
  end

  describe ".bounding_box_for" do
    it "returns a hash with bounding box keys for a known sub-district" do
      box = described_class.bounding_box_for("Glenmore")
      expect(box).to include(:lat_min, :lat_max, :lon_min, :lon_max)
      expect(box[:lat_min]).to eq(-8.30)
      expect(box[:lat_max]).to eq(-8.18)
    end

    it "is case-insensitive" do
      expect(described_class.bounding_box_for("glenmore")).not_to be_nil
    end

    it "returns nil for an unknown sub-district" do
      expect(described_class.bounding_box_for("Jakarta")).to be_nil
    end
  end

  describe ".centroid_for" do
    it "returns latitude and longitude midpoints for a known sub-district" do
      centroid = described_class.centroid_for("Glenmore")
      expect(centroid).to include(:latitude, :longitude)
      # Glenmore midpoint: lat (-8.30 + -8.18)/2 = -8.24, lon (114.03 + 114.18)/2 = 114.105
      expect(centroid[:latitude]).to be_within(0.01).of(-8.24)
      expect(centroid[:longitude]).to be_within(0.01).of(114.105)
    end

    it "returns nil for an unknown sub-district" do
      expect(described_class.centroid_for("Nowhere")).to be_nil
    end
  end
end
