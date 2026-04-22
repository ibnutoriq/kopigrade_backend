Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |source, _env|
      allowed = ENV.fetch("CORS_ALLOWED_ORIGINS", "").split(",").map(&:strip)
      allowed.include?(source)
    end

    resource "/api/*",
      headers: :any,
      methods: [ :get, :post, :options ],
      expose: [ "Authorization" ]
  end
end
