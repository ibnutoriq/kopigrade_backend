require "rails_helper"

RSpec.describe "Farmer scan flow", type: :system do
  before do
    driven_by(:rack_test)
  end

  it "visits home, navigates to new scan, fills the form, and lands on result page in pending state" do
    visit root_path

    expect(page).to have_content("Cek mutu kopi Anda")
    expect(page).to have_content("dalam 1 menit")

    click_on "Mulai Cek Mutu Kopi"

    expect(page).to have_content("Cek Mutu Kopi Anda")
    expect(current_path).to eq(new_web_scan_path)

    fill_in "Total biji yang dihitung", with: "300"
    fill_in "Biji hitam", with: "5"
    fill_in "Biji pecah", with: "10"
    select "Glenmore", from: "scan_result[sub_district]"

    click_on "Cek Mutu & Saran"

    expect(current_path).to eq(web_scan_path(ScanResult.last))
    expect(page).to have_content("Sedang menganalisa")
    expect(ScanResult.last.status).to eq("pending")
  end
end
