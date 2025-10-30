class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  
  validates :whatsapp_client, presence: true
  validates :whatsapp_client, uniqueness: { scope: :user_id }
  
  def latest_messages(limit = 4)
    messages.order(created_at: :desc).limit(limit).reverse
  end
end
