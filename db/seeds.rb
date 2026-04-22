User.find_or_create_by!(email_address: "admin@kopigrade.local") do |u|
  u.password = u.password_confirmation = "password123"
  u.admin = true
end
puts "Seeded admin: admin@kopigrade.local / password123"

unless ApiClient.exists?(name: "Flutter Mobile Dev")
  plaintext, digest = ApiClient.generate_token
  ApiClient.create!(name: "Flutter Mobile Dev", token_digest: digest)
  puts "Seeded ApiClient 'Flutter Mobile Dev'. TOKEN (shown once — store it now): #{plaintext}"
else
  puts "ApiClient 'Flutter Mobile Dev' already exists"
end

today = Date.current
[
  { variety: "robusta", price: 65_000 },
  { variety: "arabika", price: 92_000 }
].each do |attrs|
  MarketPrice.find_or_create_by!(variety: attrs[:variety], price_date: today) do |mp|
    mp.price      = attrs[:price]
    mp.source_url = "https://siskaperbapo.jatimprov.go.id/harga/tabel"
  end
end
puts "Seeded sample market prices for #{today}"
