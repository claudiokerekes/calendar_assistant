class Message < ApplicationRecord
  belongs_to :conversation
  
  enum user_type: { user: 0, system: 1 }
  
  validates :message_content, presence: true
  validates :user_type, presence: true
  validates :prompt_tokens, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :completion_tokens, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :for_context, ->(limit = 4) { recent.limit(limit).reverse }
end
