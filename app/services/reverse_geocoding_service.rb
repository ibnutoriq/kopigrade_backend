class ReverseGeocodingService
  FALLBACK = "Banyuwangi (unknown)".freeze

  def self.lookup(latitude, longitude)
    new(latitude.to_f, longitude.to_f).lookup
  end

  def initialize(latitude, longitude)
    @lat = latitude
    @lon = longitude
  end

  def lookup
    sub_districts.each do |entry|
      if @lat.between?(entry["lat_min"], entry["lat_max"]) &&
         @lon.between?(entry["lon_min"], entry["lon_max"])
        return entry["name"]
      end
    end
    FALLBACK
  end

  private

  def sub_districts
    @sub_districts ||= YAML.load_file(
      Rails.root.join("config", "banyuwangi_sub_districts.yml")
    )["sub_districts"]
  end
end
