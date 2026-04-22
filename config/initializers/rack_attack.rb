class Rack::Attack
  # Throttle API clients: 60 requests per minute per bearer token
  throttle("api/by_token", limit: 60, period: 1.minute) do |req|
    if req.path.start_with?("/api/v1/")
      header = req.env["HTTP_AUTHORIZATION"].to_s
      header.start_with?("Bearer ") ? Digest::SHA256.hexdigest(header) : req.ip
    end
  end

  # Block suspicious requests to non-API paths
  blocklist("block/bad_agents") do |req|
    req.user_agent.to_s.match?(/sqlmap|nikto|nmap|masscan/i)
  end
end
