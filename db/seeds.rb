admin_email = ENV.fetch("ADMIN_SEED_EMAIL", "admin@kopigrade.local")
admin_password = ENV.fetch("ADMIN_SEED_PASSWORD") { SecureRandom.hex(16) }

created = User.find_or_create_by!(email_address: admin_email) do |u|
  u.password = u.password_confirmation = admin_password
  u.admin = true
end

if created.previously_new_record?
  puts "Seeded admin: #{admin_email} / #{admin_password}"
else
  puts "Admin #{admin_email} already exists"
end

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
