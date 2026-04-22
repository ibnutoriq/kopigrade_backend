module Sni
  module DefectValues
    # Defect values per bean per SNI 01-2907-2008 Table 1
    # (only types detectable by ML Kit are marked as DETECTED)
    VALUES = {
      biji_hitam_full:       1.0,   # DETECTED — full black bean
      biji_hitam_sebagian:   0.5,
      biji_hitam_pecah:      0.5,
      biji_coklat:           0.25,
      biji_pecah:            0.2,   # DETECTED — broken/cracked bean
      biji_muda:             0.2,
      biji_berlubang_satu:   0.1,
      biji_berlubang_lebih:  0.2,
      biji_bertutul:         0.1,
      kulit_tanduk:          0.5,
      kotoran:               1.0,
      biji_berkulit_tanduk:  0.2,
      biji_keriput:          0.2,
      fragmen_biji:          0.2,
      biji_bertampang:       0.1
    }.freeze

    DETECTED = %i[biji_hitam_full biji_pecah].freeze
  end
end
