class SiskaperbapoScraperService
  BASE_URL = "https://siskaperbapo.jatimprov.go.id/harga/tabel".freeze

  VARIETY_MAP = {
    "kopi robusta" => "robusta",
    "kopi arabika" => "arabika",
    "kopi arabica" => "arabika"
  }.freeze

  def call
    response = HTTParty.get(BASE_URL, timeout: 20, headers: { "User-Agent" => "KopiGrade/1.0" })
    raise "HTTP #{response.code}" unless response.success?

    parse(response.body)
  rescue HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    raise "Siskaperbapo unreachable: #{e.message}"
  end

  private

  def parse(html)
    doc    = Nokogiri::HTML(html)
    prices = []
    today  = Date.current

    doc.css("table tbody tr").each do |row|
      cells = row.css("td").map { |td| td.text.strip }
      next if cells.size < 3

      commodity = cells[0].downcase
      variety   = VARIETY_MAP[commodity]
      next unless variety

      # Price is the last numeric column; use cells[2] as primary source
      price_text = cells[2]
      price = price_text.gsub(/[^0-9]/, "").to_i

      if price.zero?
        Rails.logger.warn("SiskaperbapoScraperService: could not parse price for #{variety} from '#{price_text}' — skipping")
        next
      end

      prices << { variety: variety, price: price, price_date: today, source_url: BASE_URL }
    rescue StandardError => e
      Rails.logger.warn("SiskaperbapoScraperService: skipping row due to #{e.message}")
    end

    if prices.empty?
      Rails.logger.warn("SiskaperbapoScraperService: no prices extracted — HTML structure may have changed")
    end

    prices
  end
end
