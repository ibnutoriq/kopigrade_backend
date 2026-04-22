_gemini_api_key = ENV["GOOGLE_API_KEY"].presence ||
                  Rails.application.credentials.gemini_api_key.presence

if _gemini_api_key
  GEMINI_CLIENT = Gemini.new(
    credentials: {
      service: "generative-language-api",
      api_key: _gemini_api_key,
      version: "v1beta"
    },
    options: { model: "gemini-2.5-flash" }
  )
end
