class Schedule < ApplicationRecord
  belongs_to :calendar
  has_one :user, through: :calendar
  
  validates :title, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time
  
  scope :upcoming, -> { where('start_time >= ?', Time.current).order(start_time: :asc) }
  scope :past, -> { where('end_time < ?', Time.current).order(start_time: :desc) }
  scope :on_date, ->(date) { where('DATE(start_time) = ?', date) }
  
  private
  
  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?
    
    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
end
