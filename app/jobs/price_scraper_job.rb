class PriceScraperJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 10.minutes, attempts: 3

  def perform
    prices = SiskaperbapoScraperService.new.call

    prices.each do |attrs|
      MarketPrice.find_or_initialize_by(variety: attrs[:variety], price_date: attrs[:price_date]).tap do |mp|
        mp.price      = attrs[:price]
        mp.source_url = attrs[:source_url]
        mp.save!
      end
    end

    Rails.logger.info("PriceScraperJob: upserted #{prices.size} price record(s)")
  end
end
