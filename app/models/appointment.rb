class Appointment < ApplicationRecord
  belongs_to :user
  has_many :calendar_syncs, dependent: :destroy

  # Observer pattern - lista de observers
  @@observers = []

  def self.add_observer(observer)
    @@observers << observer unless @@observers.include?(observer)
  end

  def self.delete_observer(observer)
    @@observers.delete(observer)
  end

  def notify_observers(event_type)
    @@observers.each do |observer|
      observer.update(event_type, self) if observer.respond_to?(:update)
    end
  end

  enum status: {
    pending: 0,
    confirmed: 1,
    cancelled: 2,
    completed: 3
  }

  validates :title, presence: true
  validates :start_datetime, presence: true
  validates :end_datetime, presence: true
  validate :end_datetime_after_start_datetime

  after_create :notify_calendar_observers
  after_update :notify_calendar_observers, if: :saved_change_to_appointment_details?
  after_destroy :notify_calendar_observers_destroy

  scope :for_date, ->(date) { where(start_datetime: date.beginning_of_day..date.end_of_day) }
  scope :active, -> { where.not(status: :cancelled) }
  scope :for_whatsapp_client, ->(client) { where(whatsapp_client: client) }

  def duration_in_minutes
    return 0 unless start_datetime && end_datetime
    ((end_datetime - start_datetime) / 1.minute).to_i
  end

  def overlaps_with?(other_appointment)
    return false unless other_appointment
    start_datetime < other_appointment.end_datetime && 
    end_datetime > other_appointment.start_datetime
  end

  def sync_status_for_service(service_type)
    calendar_syncs.find_by(service_type: service_type)&.sync_status || 'not_synced'
  end

  def formatted_datetime
    "#{start_datetime.strftime('%d/%m/%Y')} de #{start_datetime.strftime('%H:%M')} a #{end_datetime.strftime('%H:%M')}"
  end

  private

  def end_datetime_after_start_datetime
    return unless start_datetime && end_datetime
    
    errors.add(:end_datetime, "debe ser posterior a la fecha de inicio") if end_datetime <= start_datetime
  end

  def saved_change_to_appointment_details?
    saved_change_to_title? || saved_change_to_description? || 
    saved_change_to_start_datetime? || saved_change_to_end_datetime? || 
    saved_change_to_location? || saved_change_to_status?
  end

  def notify_calendar_observers
    notify_observers(:appointment_changed)
  end

  def notify_calendar_observers_destroy
    notify_observers(:appointment_deleted)
  end
end