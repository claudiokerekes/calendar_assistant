class User < ApplicationRecord
  has_secure_password
  
  has_many :calendars, dependent: :destroy
  has_many :schedules, through: :calendars
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  
  before_save :downcase_email
  
  # Generate JWT token for authentication
  def generate_token
    payload = { user_id: id, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, Rails.application.secret_key_base)
  end
  
  private
  
  def downcase_email
    self.email = email.downcase if email.present?
  end
end
