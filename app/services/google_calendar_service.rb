# Servicio para integración con Google Calendar
class GoogleCalendarService < CalendarServiceBase
  def service_name
    'google_calendar'
  end

  def available?
    user&.access_token.present? && user&.google_calendar_service.present?
  end

  def create_event(appointment)
    return handle_sync_result(appointment, nil, StandardError.new("Google Calendar no disponible")) unless available?

    begin
      event = build_google_event(appointment)
      created_event = user.google_calendar_service.insert_event('primary', event)
      
      if created_event&.id
        handle_sync_result(appointment, created_event.id)
        created_event.id
      else
        handle_sync_result(appointment, nil, StandardError.new("No se pudo crear el evento"))
        nil
      end
    rescue => e
      handle_sync_result(appointment, nil, e)
      nil
    end
  end

  def update_event(appointment, external_event_id)
    return false unless available? && external_event_id

    begin
      # Obtener el evento existente
      existing_event = user.google_calendar_service.get_event('primary', external_event_id)
      
      # Actualizar con nueva información
      updated_event = update_google_event(existing_event, appointment)
      
      # Guardar cambios
      result = user.google_calendar_service.update_event('primary', external_event_id, updated_event)
      
      handle_sync_result(appointment, result.id)
      result.id
    rescue Google::Apis::ClientError => e
      if e.message.include?('notFound')
        # Si el evento no existe en Google, crear uno nuevo
        Rails.logger.warn("Evento no encontrado en Google Calendar, creando nuevo: #{external_event_id}")
        create_event(appointment)
      else
        handle_sync_result(appointment, external_event_id, e)
        nil
      end
    rescue => e
      handle_sync_result(appointment, external_event_id, e)
      nil
    end
  end

  def delete_event(external_event_id)
    return false unless available? && external_event_id

    begin
      user.google_calendar_service.delete_event('primary', external_event_id)
      Rails.logger.info("Deleted Google Calendar event: #{external_event_id}")
      true
    rescue Google::Apis::ClientError => e
      if e.message.include?('notFound')
        # El evento ya no existe, consideramos exitoso
        Rails.logger.info("Google Calendar event already deleted: #{external_event_id}")
        true
      else
        Rails.logger.error("Failed to delete Google Calendar event: #{e.message}")
        false
      end
    rescue => e
      Rails.logger.error("Failed to delete Google Calendar event: #{e.message}")
      false
    end
  end

  def get_events_for_date(date)
    return [] unless available?

    begin
      start_time = date.beginning_of_day.iso8601
      end_time = date.end_of_day.iso8601

      events = user.google_calendar_service.list_events(
        'primary',
        time_min: start_time,
        time_max: end_time,
        single_events: true,
        order_by: 'startTime'
      )

      events.items.map do |event|
        {
          external_id: event.id,
          title: event.summary,
          start_time: event.start&.date_time || Time.parse(event.start&.date.to_s).beginning_of_day,
          end_time: event.end&.date_time || Time.parse(event.end&.date.to_s).end_of_day
        }
      end
    rescue => e
      Rails.logger.error("Failed to fetch Google Calendar events: #{e.message}")
      []
    end
  end

  private

  def build_google_event(appointment)
    Google::Apis::CalendarV3::Event.new(
      summary: appointment.title,
      description: build_description(appointment),
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: appointment.start_datetime.iso8601
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: appointment.end_datetime.iso8601
      ),
      location: appointment.location
    )
  end

  def update_google_event(event, appointment)
    event.summary = appointment.title
    event.description = build_description(appointment)
    event.location = appointment.location
    event.start = Google::Apis::CalendarV3::EventDateTime.new(
      date_time: appointment.start_datetime.iso8601
    )
    event.end = Google::Apis::CalendarV3::EventDateTime.new(
      date_time: appointment.end_datetime.iso8601
    )
    event
  end

  def build_description(appointment)
    description = appointment.description || ""
    
    if appointment.whatsapp_client
      description += "\n\n📱 Cliente WhatsApp: #{appointment.whatsapp_client}"
    end
    
    description += "\n\n🤖 Creado por Calendar Assistant"
    description.strip
  end
end