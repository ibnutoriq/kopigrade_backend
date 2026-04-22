if ENV["GOOGLE_API_KEY"].present?
  GEMINI_CLIENT = Gemini.new(
    credentials: {
      service: "generative-language-api",
      api_key: ENV["GOOGLE_API_KEY"]
    },
    options: { model: "gemini-1.5-flash" }
  )
end
