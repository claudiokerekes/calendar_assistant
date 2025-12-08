class Api::V1::CalendarController < ApplicationController
  skip_before_action :verify_authenticity_token # Skip CSRF for API endpoints
  before_action :require_api_authentication, except: [:user_schedule, :user_schedule_for_day]
  before_action :ensure_google_calendar_access, except: [:user_schedule, :user_schedule_for_day]
  
  # GET /api/v1/calendar/events?date=2023-10-24
  def events
    puts "DATE PARAM: #{params[:date]}"
    date = Date.parse(params[:date]) rescue Date.current
    start_time = date.beginning_of_day.iso8601
    end_time = date.end_of_day.iso8601
    
    # Obtener la configuración de horarios para el día consultado
    day_of_week = date.wday
    calendar_configs = @current_user.calendar_configs.active.where(day_of_week: day_of_week)
    
    begin
      events = @current_user.google_calendar_service.list_events(
        'primary',
        time_min: start_time,
        time_max: end_time,
        single_events: true,
        order_by: 'startTime'
      )
      
      # Procesar eventos ocupados como slots de tiempo simples
      occupied_slots = events.items.map do |event|
        start_dt = event.start&.date_time || Time.parse(event.start&.date.to_s).beginning_of_day
        end_dt = event.end&.date_time || Time.parse(event.end&.date.to_s).end_of_day
        
        {
          start_time: start_dt.strftime('%H:%M'),
          end_time: end_dt.strftime('%H:%M')
        }
      end
      
      # Crear respuesta humanizada para el LLM
      if calendar_configs.any?
        available_periods = calendar_configs.map { |config| "#{config.start_time.strftime('%H:%M')} a #{config.end_time.strftime('%H:%M')}" }.join(', ')
        availability_message = "Horarios de atención para #{CalendarConfig::DAY_NAMES[day_of_week]} #{date.strftime('%d/%m/%Y')}: #{available_periods}"
      else
        availability_message = "No hay horarios de atención configurados para #{CalendarConfig::DAY_NAMES[day_of_week]} #{date.strftime('%d/%m/%Y')}"
      end
      
      if occupied_slots.any?
        occupied_message = "Horarios ocupados: " + occupied_slots.map { |slot| "#{slot[:start_time]} a #{slot[:end_time]}" }.join(', ')
      else
        occupied_message = "No hay citas programadas"
      end
      
      # Crear mensaje humanizado para el LLM
      human_message = "📅 #{availability_message}\n\n"
      human_message += "🔴 #{occupied_message}\n\n"
      
      if calendar_configs.any? && occupied_slots.any?
        # Calcular horarios disponibles (simplificado)
        human_message += "✅ Puedes ofrecer citas en los horarios de atención que NO estén ocupados."
      elsif calendar_configs.any?
        human_message += "✅ Todos los horarios de atención están disponibles para citas."
      else
        human_message += "❌ No hay horarios de atención configurados para este día."
      end
      
      render json: { 
        success: true,
        message: human_message.strip,
        data: {
          date: date.strftime('%Y-%m-%d'),
          day_name: CalendarConfig::DAY_NAMES[day_of_week],
          availability_message: availability_message,
          occupied_message: occupied_message,
          has_availability: calendar_configs.any?,
          occupied_slots: occupied_slots,
          available_periods: calendar_configs.map do |config|
            {
              start_time: config.start_time.strftime('%H:%M'),
              end_time: config.end_time.strftime('%H:%M')
            }
          end
        }
      }
    rescue Google::Apis::AuthorizationError
      # Cuando no hay acceso al calendario, solo mostrar horarios de atención
      if calendar_configs.any?
        available_periods = calendar_configs.map { |config| "#{config.start_time.strftime('%H:%M')} a #{config.end_time.strftime('%H:%M')}" }.join(', ')
        availability_message = "Horarios de atención para #{CalendarConfig::DAY_NAMES[day_of_week]} #{date.strftime('%d/%m/%Y')}: #{available_periods}"
        human_message = "📅 #{availability_message}\n\n🔴 No se pueden verificar citas existentes (sin acceso al calendario)\n\n⚠️ Solo puedo mostrar horarios de atención, pero no puedo confirmar disponibilidad exacta."
      else
        availability_message = "No hay horarios de atención configurados para #{CalendarConfig::DAY_NAMES[day_of_week]} #{date.strftime('%d/%m/%Y')}"
        human_message = "📅 #{availability_message}\n\n❌ No hay horarios de atención configurados para este día."
      end
      
      render json: { 
        success: false,
        error: 'No hay acceso al calendario de Google. Solo se muestran horarios de atención configurados.',
        message: human_message,
        data: {
          date: date.strftime('%Y-%m-%d'),
          day_name: CalendarConfig::DAY_NAMES[day_of_week],
          availability_message: availability_message,
          occupied_message: "No se pueden verificar citas existentes (sin acceso al calendario)",
          has_availability: calendar_configs.any?,
          occupied_slots: [],
          available_periods: calendar_configs.map do |config|
            {
              start_time: config.start_time.strftime('%H:%M'),
              end_time: config.end_time.strftime('%H:%M')
            }
          end
        }
      }, status: :unauthorized
    rescue StandardError => e
      error_message = "❌ Error al obtener información del calendario: #{e.message}"
      
      render json: { 
        success: false,
        error: "Error interno: #{e.message}",
        message: error_message,
        data: {
          date: date.strftime('%Y-%m-%d'),
          day_name: CalendarConfig::DAY_NAMES[day_of_week],
          availability_message: "Error al obtener información",
          occupied_message: "Error al verificar disponibilidad",
          has_availability: false,
          occupied_slots: [],
          available_periods: []
        }
      }, status: :internal_server_error
    end
  end
  
  # POST /api/v1/calendar/events
  # Parametros: summary, description, fecha (YYYY-MM-DD), hora_inicio (HH:MM), hora_fin (HH:MM)
  def create_event
    begin
      # Validar parámetros requeridos
      unless params[:summary].present? && params[:fecha].present? && params[:hora_inicio].present? && params[:hora_fin].present?
        render json: { 
          success: false, 
          error: 'Faltan parámetros requeridos: summary, fecha, hora_inicio, hora_fin' 
        }, status: :bad_request
        return
      end

      # Construir fechas ISO 8601 a partir de fecha y horas
      fecha = Date.parse(params[:fecha])
      hora_inicio = Time.parse(params[:hora_inicio])
      hora_fin = Time.parse(params[:hora_fin])
      
      # Combinar fecha con horas para crear DateTime
      start_datetime = DateTime.new(fecha.year, fecha.month, fecha.day, hora_inicio.hour, hora_inicio.min)
      end_datetime = DateTime.new(fecha.year, fecha.month, fecha.day, hora_fin.hour, hora_fin.min)
      
      event = Google::Apis::CalendarV3::Event.new(
        summary: params[:summary],
        description: params[:description],
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: start_datetime
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: end_datetime
        ),
        location: params[:location]
      )
      
      if params[:attendees].present?
        event.attendees = params[:attendees].map do |attendee|
          Google::Apis::CalendarV3::EventAttendee.new(email: attendee[:email])
        end
      end
      
      created_event = @current_user.google_calendar_service.insert_event('primary', event)
      
      render json: {
        success: true,
        message: "Evento '#{created_event.summary}' creado exitosamente para el #{fecha.strftime('%d/%m/%Y')} de #{params[:hora_inicio]} a #{params[:hora_fin]}",
        event: {
          id: created_event.id,
          summary: created_event.summary,
          description: created_event.description,
          fecha: fecha.strftime('%Y-%m-%d'),
          hora_inicio: params[:hora_inicio],
          hora_fin: params[:hora_fin],
          start_time: created_event.start.date_time,
          end_time: created_event.end.date_time,
          location: created_event.location,
          html_link: created_event.html_link
        }
      }, status: :created
    rescue Google::Apis::AuthorizationError
      render json: { 
        success: false,
        error: 'No hay acceso al calendario de Google. Por favor re-autentícate.' 
      }, status: :unauthorized
    rescue Date::Error, ArgumentError => e
      render json: { 
        success: false,
        error: 'Error en formato de fecha u hora. Usa formato: fecha (YYYY-MM-DD), hora_inicio/hora_fin (HH:MM)',
        details: e.message
      }, status: :bad_request
    rescue StandardError => e
      render json: { 
        success: false,
        error: "Error al crear evento: #{e.message}" 
      }, status: :unprocessable_entity
    end
  end
  
  # PUT /api/v1/calendar/events/:id
  def update_event
    begin
      event = @current_user.google_calendar_service.get_event('primary', params[:id])
      
      event.summary = params[:summary] if params[:summary]
      event.description = params[:description] if params[:description]
      event.location = params[:location] if params[:location]
      
      if params[:start_time]
        event.start = Google::Apis::CalendarV3::EventDateTime.new(
          date_time: DateTime.parse(params[:start_time])
        )
      end
      
      if params[:end_time]
        event.end = Google::Apis::CalendarV3::EventDateTime.new(
          date_time: DateTime.parse(params[:end_time])
        )
      end
      
      updated_event = @current_user.google_calendar_service.update_event('primary', event.id, event)
      
      render json: {
        event: {
          id: updated_event.id,
          summary: updated_event.summary,
          description: updated_event.description,
          start_time: updated_event.start.date_time,
          end_time: updated_event.end.date_time,
          location: updated_event.location
        }
      }
    rescue Google::Apis::NotFoundError
      render json: { error: 'Event not found' }, status: :not_found
    rescue Google::Apis::AuthorizationError
      render json: { error: 'Calendar access denied. Please re-authenticate.' }, status: :unauthorized
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/calendar/events/:id
  def delete_event
    begin
      @current_user.google_calendar_service.delete_event('primary', params[:id])
      render json: { message: 'Event deleted successfully' }
    rescue Google::Apis::NotFoundError
      render json: { error: 'Event not found' }, status: :not_found
    rescue Google::Apis::AuthorizationError
      render json: { error: 'Calendar access denied. Please re-authenticate.' }, status: :unauthorized
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end
  
  # GET /api/v1/calendar/availability?date=2023-10-24&duration=60
  def availability
    date = Date.parse(params[:date]) rescue Date.current
    duration = (params[:duration] || 60).to_i # minutes
    
    start_time = date.beginning_of_day
    end_time = date.end_of_day
    
    begin
      # Get existing events for the day
      events = @current_user.google_calendar_service.list_events(
        'primary',
        time_min: start_time.iso8601,
        time_max: end_time.iso8601,
        single_events: true,
        order_by: 'startTime'
      )
      
      # Generate available time slots
      available_slots = generate_available_slots(start_time, end_time, events.items, duration)
      
      render json: { available_slots: available_slots }
    rescue Google::Apis::AuthorizationError
      render json: { error: 'Calendar access denied. Please re-authenticate.' }, status: :unauthorized
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end
  

  
  # GET /api/v1/calendar/schedule_config
  def schedule_config
    config = @current_user.calendar_configuration_for_llm
    
    render json: {
      success: true,
      data: config
    }
  rescue => e
    render json: {
      success: false,
      error: e.message
    }, status: 500
  end

  # GET /api/v1/calendar/schedule_config/:day
  def schedule_config_for_day
    day_of_week = params[:day].to_i
    
    unless (0..6).include?(day_of_week)
      render json: {
        success: false,
        error: 'Día de la semana inválido. Debe ser 0-6 (0=Domingo, 6=Sábado)'
      }, status: 400
      return
    end

    day_name = CalendarConfig::DAY_NAMES[day_of_week]
    configs = @current_user.calendar_config_for_day(day_of_week)
    
    if configs.any?
      day_config = {
        day_of_week: day_of_week,
        day_name: day_name,
        is_available: true,
        time_slots: configs.map do |config|
          {
            id: config.id,
            start_time: config.formatted_start_time,
            end_time: config.formatted_end_time,
            duration_hours: config.duration_in_hours,
            notes: config.notes,
            is_active: config.is_active
          }
        end,
        total_available_hours: @current_user.available_hours_for_day(day_of_week)
      }
    else
      day_config = {
        day_of_week: day_of_week,
        day_name: day_name,
        is_available: false,
        time_slots: [],
        total_available_hours: 0
      }
    end

    render json: {
      success: true,
      data: day_config
    }
  rescue => e
    render json: {
      success: false,
      error: e.message
    }, status: 500
  end

  # POST /api/v1/calendar/check_availability
  def check_availability
    date_time_str = params[:date_time]
    
    unless date_time_str
      render json: {
        success: false,
        error: 'Parámetro date_time es requerido'
      }, status: 400
      return
    end

    begin
      date_time = DateTime.parse(date_time_str)
      is_available = @current_user.is_available_at_time?(date_time)
      
      render json: {
        success: true,
        data: {
          date_time: date_time.iso8601,
          day_of_week: date_time.wday,
          day_name: CalendarConfig::DAY_NAMES[date_time.wday],
          is_available: is_available,
          user_timezone: "America/Bogota"
        }
      }
    rescue ArgumentError => e
      render json: {
        success: false,
        error: "Formato de fecha/hora inválido: #{e.message}"
      }, status: 400
    rescue => e
      render json: {
        success: false,
        error: e.message
      }, status: 500
    end
  end

  # GET /api/v1/calendar/user_schedule/:user_id
  def user_schedule
    user_id = params[:user_id]
    
    unless user_id
      render json: {
        success: false,
        error: 'Parámetro user_id es requerido'
      }, status: 400
      return
    end

    begin
      user = User.find(user_id)
      config = user.calendar_configuration_for_llm
      
      render json: {
        success: true,
        data: config
      }
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        error: 'Usuario no encontrado'
      }, status: 404
    rescue => e
      render json: {
        success: false,
        error: e.message
      }, status: 500
    end
  end

  # GET /api/v1/calendar/user_schedule/:user_id/:day
  def user_schedule_for_day
    user_id = params[:user_id]
    day_of_week = params[:day].to_i
    
    unless user_id
      render json: {
        success: false,
        error: 'Parámetro user_id es requerido'
      }, status: 400
      return
    end

    unless (0..6).include?(day_of_week)
      render json: {
        success: false,
        error: 'Día de la semana inválido. Debe ser 0-6 (0=Domingo, 6=Sábado)'
      }, status: 400
      return
    end

    begin
      user = User.find(user_id)
      day_name = CalendarConfig::DAY_NAMES[day_of_week]
      configs = user.calendar_config_for_day(day_of_week)
      
      if configs.any?
        day_config = {
          user_id: user.id,
          user_name: user.name,
          user_email: user.email,
          day_of_week: day_of_week,
          day_name: day_name,
          is_available: true,
          time_slots: configs.map do |config|
            {
              id: config.id,
              start_time: config.formatted_start_time,
              end_time: config.formatted_end_time,
              duration_hours: config.duration_in_hours,
              notes: config.notes,
              is_active: config.is_active
            }
          end,
          total_available_hours: user.available_hours_for_day(day_of_week)
        }
      else
        day_config = {
          user_id: user.id,
          user_name: user.name,
          user_email: user.email,
          day_of_week: day_of_week,
          day_name: day_name,
          is_available: false,
          time_slots: [],
          total_available_hours: 0
        }
      end

      render json: {
        success: true,
        data: day_config
      }
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        error: 'Usuario no encontrado'
      }, status: 404
    rescue => e
      render json: {
        success: false,
        error: e.message
      }, status: 500
    end
  end

  private
  
  def ensure_google_calendar_access
    unless @current_user.access_token
      render json: { error: 'Google Calendar not connected. Please authenticate.' }, status: :unauthorized
    end
  end

  def generate_available_slots(start_time, end_time, events, duration_minutes)
    # Business hours: 9 AM to 6 PM
    business_start = start_time.change(hour: 9)
    business_end = start_time.change(hour: 18)
    
    slots = []
    current_time = business_start
    
    while current_time + duration_minutes.minutes <= business_end
      slot_end = current_time + duration_minutes.minutes
      
      # Check if this slot conflicts with any existing event
      conflict = events.any? do |event|
        event_start = DateTime.parse(event.start.date_time.to_s) if event.start.date_time
        event_end = DateTime.parse(event.end.date_time.to_s) if event.end.date_time
        
        next false unless event_start && event_end
        
        # Check for overlap
        (current_time < event_end) && (slot_end > event_start)
      end
      
      unless conflict
        slots << {
          start_time: current_time.iso8601,
          end_time: slot_end.iso8601
        }
      end
      
      current_time += 30.minutes # 30-minute intervals
    end
    
    slots
  end
end