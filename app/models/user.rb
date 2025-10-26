class User < ApplicationRecord
  has_many :whatsapp_numbers, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true
  validates :google_id, presence: true, uniqueness: true
  validates :plan, inclusion: { in: %w[basic premium enterprise] }
  validates :whatsapp_numbers_limit, numericality: { greater_than: 0 }
  
  before_validation :set_defaults, on: :create
  
  def self.from_omniauth(auth)
    user = where(google_id: auth.uid).first_or_initialize do |new_user|
      new_user.email = auth.info.email
      new_user.name = auth.info.name
      new_user.google_id = auth.uid
      new_user.provider = auth.provider
    end
    
    # Always update tokens and profile info (for both new and existing users)
    user.access_token = auth.credentials.token
    user.refresh_token = auth.credentials.refresh_token if auth.credentials.refresh_token
    user.expires_at = Time.at(auth.credentials.expires_at) if auth.credentials.expires_at
    user.email = auth.info.email
    user.name = auth.info.name
    
    user.save!
    user
  end
  
  def can_add_whatsapp_number?
    whatsapp_numbers.count < whatsapp_numbers_limit
  end
  
  def google_calendar_service
    require 'google/apis/calendar_v3'
    require 'googleauth'
    
    service = Google::Apis::CalendarV3::CalendarService.new
    
    # Create credentials from stored tokens
    credentials = Google::Auth::UserRefreshCredentials.new(
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      scope: ['https://www.googleapis.com/auth/calendar'],
      access_token: access_token,
      refresh_token: refresh_token
    )
    
    service.authorization = credentials
    service
  end
  
  private
  
  def set_defaults
    self.plan ||= 'basic'
    self.whatsapp_numbers_limit ||= 1
  end
end
