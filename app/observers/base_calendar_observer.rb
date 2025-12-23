# Observer abstracto base para sincronización de calendarios
class BaseCalendarObserver
  def initialize
    @enabled_services = []
  end

  # Método principal que deben implementar los observers concretos
  def update(event_type, appointment)
    return unless should_process_event?(event_type, appointment)

    case event_type
    when :appointment_changed
      handle_appointment_change(appointment)
    when :appointment_deleted
      handle_appointment_deletion(appointment)
    else
      handle_custom_event(event_type, appointment)
    end
  rescue => e
    handle_error(event_type, appointment, e)
  end

  # Registrar un servicio para este observer
  def register_service(service_name)
    @enabled_services << service_name unless @enabled_services.include?(service_name)
  end

  # Desregistrar un servicio
  def unregister_service(service_name)
    @enabled_services.delete(service_name)
  end

  # Verificar si un servicio está habilitado
  def service_enabled?(service_name)
    @enabled_services.include?(service_name)
  end

  protected

  # Métodos que pueden sobreescribir las subclases
  def should_process_event?(event_type, appointment)
    true # Por defecto procesar todos los eventos
  end

  def handle_appointment_change(appointment)
    raise NotImplementedError, "Subclass must implement handle_appointment_change"
  end

  def handle_appointment_deletion(appointment)
    raise NotImplementedError, "Subclass must implement handle_appointment_deletion"
  end

  def handle_custom_event(event_type, appointment)
    Rails.logger.warn("Unhandled event type: #{event_type}")
  end

  def handle_error(event_type, appointment, error)
    Rails.logger.error("Calendar sync error for #{event_type}: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
  end

  # Método de utilidad para obtener servicios de calendario
  def get_calendar_service(service_type, user)
    case service_type
    when 'google_calendar'
      GoogleCalendarService.new(user)
    when 'outlook'
      # OutlookCalendarService.new(user) # Para futuro
      nil
    when 'apple_calendar'
      # AppleCalendarService.new(user) # Para futuro
      nil
    else
      nil
    end
  end
end