module WebRequestHelper
  MODERN_BROWSER_UA = "Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36".freeze

  def web_headers
    { "User-Agent" => MODERN_BROWSER_UA }
  end
end

RSpec.configure do |config|
  config.include WebRequestHelper, type: :request
  config.include WebRequestHelper, type: :system
end
