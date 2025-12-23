# Servicio base para integración con calendarios externos
class CalendarServiceBase
  attr_reader :user

  def initialize(user)
    @user = user
  end

  # Métodos que deben implementar las subclases
  def create_event(appointment)
    raise NotImplementedError, "Subclass must implement create_event"
  end

  def update_event(appointment, external_event_id)
    raise NotImplementedError, "Subclass must implement update_event"
  end

  def delete_event(external_event_id)
    raise NotImplementedError, "Subclass must implement delete_event"
  end

  def service_name
    raise NotImplementedError, "Subclass must implement service_name"
  end

  def available?
    raise NotImplementedError, "Subclass must implement available?"
  end

  protected

  # Método común para manejar resultados de sincronización
  def handle_sync_result(appointment, external_event_id, error = nil)
    sync_record = appointment.calendar_syncs.find_or_initialize_by(
      service_type: service_name
    )

    if error
      sync_record.update!(
        sync_status: :failed,
        error_message: error.message,
        last_synced_at: Time.current
      )
      Rails.logger.error("Calendar sync failed for #{service_name}: #{error.message}")
      false
    else
      sync_record.update!(
        external_event_id: external_event_id,
        sync_status: :synced,
        error_message: nil,
        last_synced_at: Time.current
      )
      Rails.logger.info("Calendar synced successfully for #{service_name}: #{external_event_id}")
      true
    end
  end

  # Método de utilidad para validar fecha/hora
  def validate_datetime(datetime)
    return false unless datetime.is_a?(DateTime) || datetime.is_a?(Time)
    return false if datetime < Time.current
    true
  end

  # Método de utilidad para formatear errores
  def format_error(error)
    case error
    when Google::Apis::AuthorizationError
      "Acceso denegado al calendario. Re-autenticación requerida."
    when Google::Apis::ClientError
      "Error del cliente: #{error.message}"
    when Google::Apis::ServerError
      "Error del servidor de calendario: #{error.message}"
    else
      "Error de calendario: #{error.message}"
    end
  end
end