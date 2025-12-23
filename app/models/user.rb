class User < ApplicationRecord
  has_many :whatsapp_numbers, dependent: :destroy
  has_many :calendar_configs, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :appointments, dependent: :destroy
  
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

  # Métodos para configuración de calendario
  def active_calendar_configs
    calendar_configs.active.order(:day_of_week, :start_time)
  end

  def calendar_config_for_day(day_of_week)
    calendar_configs.active.by_day(day_of_week)
  end

  def is_available_on_day?(day_of_week)
    calendar_config_for_day(day_of_week).exists?
  end

  def is_available_at_time?(date_time)
    day_of_week = date_time.wday
    configs = calendar_config_for_day(day_of_week)
    
    configs.any? { |config| config.includes_time?(date_time) }
  end

  def available_hours_for_day(day_of_week)
    configs = calendar_config_for_day(day_of_week)
    total_hours = 0
    
    configs.each do |config|
      total_hours += config.duration_in_hours
    end
    
    total_hours
  end

  # Obtiene toda la configuración en formato JSON para n8n
  def calendar_configuration_for_llm
    config_data = {
      user_id: id,
      user_name: name,
      user_email: email,
      timezone: "America/Bogota", # Puedes hacer esto configurable
      weekly_schedule: {}
    }

    CalendarConfig::DAY_NAMES.each do |day_num, day_name|
      day_configs = calendar_config_for_day(day_num)
      
      if day_configs.any?
        config_data[:weekly_schedule][day_name.downcase] = {
          is_available: true,
          time_slots: day_configs.map do |config|
            {
              start_time: config.formatted_start_time,
              end_time: config.formatted_end_time,
              duration_hours: config.duration_in_hours,
              notes: config.notes
            }
          end
        }
      else
        config_data[:weekly_schedule][day_name.downcase] = {
          is_available: false,
          time_slots: []
        }
      end
    end

    config_data
  end
  
  private
  
  def set_defaults
    self.plan ||= 'basic'
    self.whatsapp_numbers_limit ||= 1
  end
end
