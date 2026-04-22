namespace :api do
  namespace :clients do
    desc "Create an API client and print its token once. Usage: rake 'api:clients:create[name]'"
    task :create, [ :name ] => :environment do |_, args|
      name = args[:name].presence || abort("Usage: rake 'api:clients:create[Client Name]'")
      plaintext, digest = ApiClient.generate_token
      client = ApiClient.create!(name: name, token_digest: digest)
      puts "Created ApiClient ##{client.id}: #{client.name}"
      puts "TOKEN (shown once — store it securely):"
      puts plaintext
    end
  end
end
