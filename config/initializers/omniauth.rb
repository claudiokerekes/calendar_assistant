Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], {
    scope: %w[email profile openid https://www.googleapis.com/auth/calendar].join(' '),
    access_type: 'offline',
    prompt: 'consent select_account',
    # Explicitly set the redirect URI to match what we configure in Google
    redirect_uri: "#{ENV['BASE_URL'] || 'http://localhost:3000'}/auth/google_oauth2/callback"
  }
end

# OmniAuth configuration
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true