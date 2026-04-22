class CreateScanResults < ActiveRecord::Migration[8.1]
  def change
    create_table :scan_results do |t|
      t.references :api_client, null: true, foreign_key: true
      t.string :device_id
      t.integer :total_beans, null: false
      t.integer :black_defects, null: false, default: 0
      t.integer :broken_defects, null: false, default: 0
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :sub_district
      t.string :variety, default: "robusta"
      t.text :advice
      t.string :status, default: "pending"
      t.datetime :scanned_at
      t.text :error_message
      t.decimal :sni_defect_value, precision: 6, scale: 2
      t.string :sni_grade
      t.boolean :export_eligible

      t.timestamps
    end

    add_index :scan_results, :status
    add_index :scan_results, :created_at
    add_index :scan_results, :sub_district
    add_index :scan_results, :sni_grade
  end
end
