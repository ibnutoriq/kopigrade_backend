class CreateMarketPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :market_prices do |t|
      t.string :variety, null: false
      t.integer :price, null: false
      t.date :price_date, null: false
      t.string :source_url

      t.timestamps
    end

    add_index :market_prices, [ :variety, :price_date ], unique: true
  end
end
