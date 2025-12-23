class CalendarSync < ApplicationRecord
  belongs_to :appointment

  enum sync_status: {
    pending: 0,
    synced: 1,
    failed: 2,
    deleted: 3
  }

  validates :service_type, presence: true, uniqueness: { scope: :appointment_id }

  scope :for_service, ->(service) { where(service_type: service) }
  scope :needs_sync, -> { where(sync_status: [:pending, :failed]) }
  scope :successful, -> { where(sync_status: :synced) }

  def service_display_name
    case service_type
    when 'google_calendar'
      'Google Calendar'
    when 'outlook'
      'Microsoft Outlook'
    when 'apple_calendar'
      'Apple Calendar'
    else
      service_type.humanize
    end
  end

  def last_error
    return nil if sync_status != 'failed'
    error_message.presence || 'Error desconocido'
  end
end