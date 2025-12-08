class Calendar < ApplicationRecord
  belongs_to :user
  has_many :schedules, dependent: :destroy
  
  validates :name, presence: true
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :timezone, presence: true
  
  # Default timezone to UTC if not specified
  after_initialize :set_default_timezone, if: :new_record?
  
  private
  
  def set_default_timezone
    self.timezone ||= 'UTC'
  end
end
