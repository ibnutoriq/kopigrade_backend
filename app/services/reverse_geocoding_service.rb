class ReverseGeocodingService
  FALLBACK = "Banyuwangi (unknown)".freeze

  def self.lookup(latitude, longitude)
    new(latitude.to_f, longitude.to_f).lookup
  end

  def self.all_sub_districts
    load_sub_districts.map { |e| e["name"] }.sort
  end

  def self.bounding_box_for(name)
    entry = load_sub_districts.find { |e| e["name"].casecmp(name.to_s).zero? }
    return nil unless entry
    { lat_min: entry["lat_min"], lat_max: entry["lat_max"],
      lon_min: entry["lon_min"], lon_max: entry["lon_max"] }
  end

  def self.centroid_for(name)
    box = bounding_box_for(name)
    return nil unless box
    { latitude: ((box[:lat_min] + box[:lat_max]) / 2.0).round(6),
      longitude: ((box[:lon_min] + box[:lon_max]) / 2.0).round(6) }
  end

  def self.load_sub_districts
    @load_sub_districts ||= YAML.load_file(
      Rails.root.join("config", "banyuwangi_sub_districts.yml")
    )["sub_districts"]
  end

  def initialize(latitude, longitude)
    @lat = latitude
    @lon = longitude
  end

  def lookup
    self.class.load_sub_districts.each do |entry|
      if @lat.between?(entry["lat_min"], entry["lat_max"]) &&
         @lon.between?(entry["lon_min"], entry["lon_max"])
        return entry["name"]
      end
    end
    FALLBACK
  end
end
