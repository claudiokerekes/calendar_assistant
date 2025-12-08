# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In production, restrict this to specific domains
    # Example: origins 'https://yourdomain.com', 'https://n8n.yourdomain.com'
    origins Rails.env.production? ? ENV.fetch('ALLOWED_ORIGINS', '').split(',') : '*'
    
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization']
  end
end
