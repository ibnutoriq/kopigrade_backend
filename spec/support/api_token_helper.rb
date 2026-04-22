module ApiTokenHelper
  def api_token_for(client)
    plaintext, digest = ApiClient.generate_token
    client.update!(token_digest: digest)
    plaintext
  end

  def bearer_headers(client)
    { "Authorization" => "Bearer #{api_token_for(client)}", "Content-Type" => "application/json" }
  end
end

RSpec.configure do |config|
  config.include ApiTokenHelper, type: :request
end
