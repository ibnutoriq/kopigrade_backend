module SniGrading
  extend ActiveSupport::Concern

  PARTIAL_COVERAGE_NOTICE = "Estimasi SNI hanya berdasarkan biji hitam dan biji pecah; " \
    "jenis cacat lain belum terdeteksi."

  included do
    before_save :compute_sni_grade!
  end

  def defect_rate
    return 0.0 if total_beans.to_i.zero?
    (black_defects.to_f + broken_defects.to_f) / total_beans * 100
  end

  def sni_grade_label
    return sni_grade.to_s if sni_grade.blank?
    I18n.t("sni.grades.#{sni_grade}", default: sni_grade)
  end

  def export_eligible?
    export_eligible
  end

  private

  def compute_sni_grade!
    return unless total_beans.to_i > 0

    cfg         = sni_config
    variety_key = (variety || "robusta").to_sym
    ref_beans   = cfg.dig(:reference_beans_per_300g, variety_key).to_f

    scale_factor   = ref_beans / total_beans.to_f
    raw_defect     = (black_defects.to_f * 1.0) + (broken_defects.to_f * 0.2)
    computed_value = (raw_defect * scale_factor).round(1)

    self.sni_defect_value = computed_value
    self.sni_grade        = bucket_grade(computed_value, variety_key, cfg)
    self.export_eligible  = compute_export_eligibility(computed_value, variety_key, cfg)
  end

  def bucket_grade(defect_value, variety_key, cfg)
    thresholds = cfg.dig(:grade_thresholds, variety_key) || []
    thresholds.each do |entry|
      return entry[:grade].to_s if defect_value <= entry[:max].to_f
    end
    "Di luar mutu"
  end

  def compute_export_eligibility(defect_value, variety_key, cfg)
    threshold = cfg.dig(:export_thresholds, variety_key).to_f
    defect_value <= threshold
  end

  def sni_config
    @sni_config ||= Rails.application.config_for(:sni_grading)
  end
end
