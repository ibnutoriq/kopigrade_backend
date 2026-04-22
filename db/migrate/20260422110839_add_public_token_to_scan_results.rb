class AddPublicTokenToScanResults < ActiveRecord::Migration[8.1]
  def up
    add_column :scan_results, :public_token, :string
    ScanResult.find_each do |s|
      s.update_column(:public_token, SecureRandom.alphanumeric(8))
    end
    change_column_null :scan_results, :public_token, false
    add_index :scan_results, :public_token, unique: true
  end

  def down
    remove_column :scan_results, :public_token
  end
end
