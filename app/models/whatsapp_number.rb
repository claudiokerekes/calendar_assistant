class WhatsappNumber < ApplicationRecord
  belongs_to :user
  
  validates :phone_number, presence: true, uniqueness: true
  validates :phone_number, format: { with: /\A\+?[1-9]\d{1,14}\z/, message: "must be a valid phone number" }
  validate :user_can_add_number, on: :create
  
  scope :active, -> { where(is_active: true) }
  
  private
  
  def user_can_add_number
    return unless user
    
    unless user.can_add_whatsapp_number?
      errors.add(:base, "User has reached the limit of WhatsApp numbers for their plan")
    end
  end
end
