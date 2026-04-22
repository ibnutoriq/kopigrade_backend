require "rails_helper"

RSpec.describe ScanResult, type: :model do
  # Builds a ScanResult whose sni_defect_value == target after save.
  # black_defects * 1.0 * (ref / total) = target  =>  black = ceil(target * total / ref)
  def scan_for_sni(target, variety: "robusta", total: 1800)
    ref   = variety == "robusta" ? 1800 : 2000
    black = (target.to_f * total / ref).ceil.clamp(0, total)
    build(:scan_result, total_beans: total, black_defects: black, broken_defects: 0, variety: variety)
  end

  # ── Validations ─────────────────────────────────────────────────────────────

  describe "validations" do
    it "is valid with required fields" do
      expect(build(:scan_result)).to be_valid
    end

    it "requires total_beans" do
      expect(build(:scan_result, total_beans: nil)).not_to be_valid
    end

    it "requires total_beans > 0" do
      expect(build(:scan_result, total_beans: 0)).not_to be_valid
    end

    it "requires total_beans ≤ 10_000" do
      expect(build(:scan_result, total_beans: 10_001)).not_to be_valid
    end

    it "requires black_defects ≤ total_beans" do
      expect(build(:scan_result, total_beans: 100, black_defects: 101, broken_defects: 0)).not_to be_valid
    end

    it "requires black + broken ≤ total_beans" do
      scan = build(:scan_result, total_beans: 100, black_defects: 60, broken_defects: 50)
      expect(scan).not_to be_valid
      expect(scan.errors[:base]).not_to be_empty
    end

    it "requires latitude within Banyuwangi bounding box" do
      scan = build(:scan_result, latitude: -5.0, longitude: 114.0)
      expect(scan).not_to be_valid
      expect(scan.errors[:latitude]).not_to be_empty
    end

    it "requires longitude within Banyuwangi bounding box" do
      scan = build(:scan_result, latitude: -8.2, longitude: 112.0)
      expect(scan).not_to be_valid
      expect(scan.errors[:longitude]).not_to be_empty
    end

    it "rejects unknown variety enum values" do
      expect { build(:scan_result, variety: "liberica") }.to raise_error(ArgumentError)
    end
  end

  # ── SNI Grading — Robusta ───────────────────────────────────────────────────

  describe "SNI grading — Robusta" do
    [
      [ "Mutu 1",  11 ],
      [ "Mutu 2",  12 ],
      [ "Mutu 2",  25 ],
      [ "Mutu 3",  26 ],
      [ "Mutu 3",  44 ],
      [ "Mutu 4a", 45 ],
      [ "Mutu 4a", 60 ],
      [ "Mutu 4b", 61 ],
      [ "Mutu 4b", 80 ],
      [ "Mutu 5",  81 ],
      [ "Mutu 5",  150 ],
      [ "Mutu 6",  151 ],
      [ "Mutu 6",  225 ]
    ].each do |grade, value|
      it "assigns #{grade} at defect value #{value}" do
        scan = scan_for_sni(value)
        scan.save!
        expect(scan.sni_grade).to eq(grade)
      end
    end

    it "assigns Di luar mutu above 225" do
      scan = scan_for_sni(226)
      scan.save!
      expect(scan.sni_grade).to eq("Di luar mutu")
    end

    it "marks export_eligible at ≤ 150" do
      scan = scan_for_sni(150)
      scan.save!
      expect(scan.export_eligible).to be true
    end

    it "marks not export_eligible at 151" do
      scan = scan_for_sni(151)
      scan.save!
      expect(scan.export_eligible).to be false
    end
  end

  # ── SNI Grading — Arabika ───────────────────────────────────────────────────

  describe "SNI grading — Arabika" do
    it "assigns Mutu 1 at 11" do
      scan = scan_for_sni(11, variety: "arabika", total: 2000)
      scan.save!
      expect(scan.sni_grade).to eq("Mutu 1")
    end

    it "assigns merged Mutu 4 (not 4a/4b) at 45" do
      scan = scan_for_sni(45, variety: "arabika", total: 2000)
      scan.save!
      expect(scan.sni_grade).to eq("Mutu 4")
    end

    it "assigns Mutu 4 at upper boundary 80" do
      scan = scan_for_sni(80, variety: "arabika", total: 2000)
      scan.save!
      expect(scan.sni_grade).to eq("Mutu 4")
    end

    it "marks export_eligible at ≤ 86" do
      scan = scan_for_sni(86, variety: "arabika", total: 2000)
      scan.save!
      expect(scan.export_eligible).to be true
    end

    it "marks not export_eligible at 87" do
      scan = scan_for_sni(87, variety: "arabika", total: 2000)
      scan.save!
      expect(scan.export_eligible).to be false
    end
  end

  # ── Computed helpers ─────────────────────────────────────────────────────────

  describe "#defect_rate" do
    it "calculates percentage of defective beans" do
      scan = build(:scan_result, total_beans: 200, black_defects: 10, broken_defects: 10)
      expect(scan.defect_rate).to be_within(0.01).of(10.0)
    end

    it "returns 0 when total_beans is zero" do
      scan = build(:scan_result, total_beans: 1, black_defects: 0, broken_defects: 0)
      scan.total_beans = 0
      expect(scan.defect_rate).to eq(0.0)
    end
  end

  describe "#sni_grade_label" do
    it "returns a human-readable Indonesian label" do
      scan = build(:scan_result, total_beans: 1800, black_defects: 12, broken_defects: 0)
      scan.save!
      expect(scan.sni_grade_label).to match(/Mutu/)
    end
  end
end
