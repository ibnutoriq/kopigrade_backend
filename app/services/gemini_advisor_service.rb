class GeminiAdvisorService
  Result = Struct.new(:advice, :success?, keyword_init: true)

  SYSTEM_INSTRUCTION = <<~INST.freeze
    Kamu adalah penasihat mutu kopi SNI untuk petani Banyuwangi. Jawab dalam Bahasa Indonesia. \
    Tanpa salam pembuka. Langsung ke isi. Tanpa format bold atau italic. \
    Tulis tepat 3 paragraf, masing-masing maksimal 3 kalimat: \
    (1) Grade SNI: sebutkan grade, artinya secara komersial, dan ingatkan bahwa estimasi hanya mencakup biji hitam dan biji pecah. \
    (2) Saran pasca panen: 1–2 tindakan konkret untuk mengurangi cacat dominan, disesuaikan iklim Banyuwangi. \
    (3) Harga: kisaran harga realistis hari ini berdasarkan grade dan kelayakan ekspor ICO 407 — satu angka konkret. \
    Total maksimal 100 kata.
  INST

  TIMEOUT_SECONDS = 15

  def initialize(scan_result)
    @scan = scan_result
  end

  def call
    unless defined?(GEMINI_CLIENT) && GEMINI_CLIENT
      return Result.new(
        advice: "Layanan AI belum dikonfigurasi. Hubungi administrator untuk mengaktifkan GOOGLE_API_KEY.",
        success?: false
      )
    end

    response = GEMINI_CLIENT.generate_content({
      systemInstruction: { parts: [{ text: SYSTEM_INSTRUCTION }] },
      contents: [{ role: "user", parts: [{ text: build_user_prompt }] }]
    })
    advice_text = response.dig("candidates", 0, "content", "parts", 0, "text")
    raise "Empty Gemini response" if advice_text.blank?

    Result.new(advice: advice_text, success?: true)
  rescue StandardError => e
    Rails.logger.error("GeminiAdvisorService error: #{e.class}: #{e.message}")
    Result.new(advice: nil, success?: false)
  end

  private

  def build_user_prompt
    market = MarketPrice.latest_for(@scan.variety.to_s)
    price_text = market ? "Rp #{market.price}/kg (tanggal #{market.price_date})" : "tidak tersedia"

    black_pct  = format("%.1f", (@scan.black_defects.to_f / @scan.total_beans * 100))
    broken_pct = format("%.1f", (@scan.broken_defects.to_f / @scan.total_beans * 100))

    # All values are controlled integers, decimals, or whitelist strings — no free-text user input
    <<~PROMPT
      Data scan dari #{safe_string(@scan.sub_district) || 'lokasi tidak diketahui'}, Banyuwangi:
      - Varietas: #{safe_variety(@scan.variety)}
      - Total biji pada sample: #{@scan.total_beans.to_i}
      - Biji hitam: #{@scan.black_defects.to_i} (#{black_pct}%)
      - Biji pecah: #{@scan.broken_defects.to_i} (#{broken_pct}%)
      - Estimasi nilai cacat SNI (ekstrapolasi ke 300 g): #{@scan.sni_defect_value}
      - Grade SNI (estimasi, cakupan parsial): #{@scan.sni_grade_label}
      - Layak ekspor per ICO 407: #{@scan.export_eligible? ? 'Ya' : 'Tidak'}
      - Harga pasar #{safe_variety(@scan.variety)} Banyuwangi hari ini: #{price_text}
      - Catatan: estimasi SNI hanya memperhitungkan biji hitam dan biji pecah; cacat lain (biji muda, berlubang, coklat, kulit tanduk, kotoran) belum terdeteksi oleh aplikasi.

      Berikan saran sesuai instruksi sistem.
    PROMPT
  end

  def safe_string(value)
    value.to_s.gsub(/[^a-zA-Z0-9\s\-,.]/, "").strip.presence
  end

  def safe_variety(variety)
    ScanResult::VARIETIES.include?(variety.to_s) ? variety.to_s : "robusta"
  end
end
