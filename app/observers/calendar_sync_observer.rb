# Observer concreto para sincronización de calendarios
class CalendarSyncObserver < BaseCalendarObserver
  def initialize
    super
    register_service('google_calendar')
    # En el futuro: register_service('outlook'), register_service('apple_calendar')
  end

  protected

  def handle_appointment_change(appointment)
    sync_with_enabled_services(appointment)
  end

  def handle_appointment_deletion(appointment)
    delete_from_enabled_services(appointment)
  end

  private

  def sync_with_enabled_services(appointment)
    @enabled_services.each do |service_type|
      next unless service_enabled?(service_type)
      
      sync_with_service(appointment, service_type)
    end
  end

  def delete_from_enabled_services(appointment)
    appointment.calendar_syncs.each do |sync|
      next unless service_enabled?(sync.service_type)
      
      delete_from_service(appointment, sync)
    end
  end

  def sync_with_service(appointment, service_type)
    return unless appointment.user

    service = get_calendar_service(service_type, appointment.user)
    return unless service

    existing_sync = appointment.calendar_syncs.find_by(service_type: service_type)

    if existing_sync&.external_event_id
      # Update existing event
      Rails.logger.info("Updating #{service_type} event for appointment #{appointment.id}")
      service.update_event(appointment, existing_sync.external_event_id)
    else
      # Create new event
      Rails.logger.info("Creating #{service_type} event for appointment #{appointment.id}")
      service.create_event(appointment)
    end
  rescue => e
    Rails.logger.error("Failed to sync with #{service_type}: #{e.message}")
  end

  def delete_from_service(appointment, sync)
    return unless sync.external_event_id

    service = get_calendar_service(sync.service_type, appointment.user)
    return unless service

    Rails.logger.info("Deleting #{sync.service_type} event #{sync.external_event_id}")
    
    if service.delete_event(sync.external_event_id)
      sync.update!(sync_status: :deleted)
    else
      sync.update!(sync_status: :failed, error_message: "Failed to delete from #{sync.service_type}")
    end
  rescue => e
    Rails.logger.error("Failed to delete from #{sync.service_type}: #{e.message}")
    sync.update!(sync_status: :failed, error_message: e.message)
  end
end