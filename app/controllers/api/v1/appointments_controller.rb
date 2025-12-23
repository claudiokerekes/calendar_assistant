class Api::V1::AppointmentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  # before_action :require_api_authentication  # Temporalmente deshabilitado para testing
  before_action :set_current_user_for_testing
  before_action :set_appointment, only: [:show, :update, :destroy]

  # Configuración: horas mínimas de anticipación requeridas para crear una cita
  MINIMUM_ADVANCE_HOURS = 1

  # GET /api/v1/appointments?date=2025-12-10
  def index
    date = Date.parse(params[:date]) rescue Date.current
    appointments = @current_user.appointments.for_date(date).includes(:calendar_syncs)

    # Obtener también eventos de Google Calendar para mostrar ocupación completa
    google_service = GoogleCalendarService.new(@current_user)
    google_events = google_service.available? ? google_service.get_events_for_date(date) : []

    # Crear mensaje humanizado
    availability_message = build_availability_message(date, appointments, google_events)

    render json: {
      success: true,
      message: availability_message,
      data: {
        date: date.strftime('%Y-%m-%d'),
        day_name: CalendarConfig::DAY_NAMES[date.wday],
        appointments: appointments.map { |apt| format_appointment(apt) },
        google_events: google_events.map { |event| format_google_event(event) },
        total_appointments: appointments.count,
        google_calendar_connected: google_service.available?
      }
    }
  end

  # GET /api/v1/appointments/:id
  def show
    render json: {
      success: true,
      data: format_appointment_detailed(@appointment)
    }
  end

  # POST /api/v1/appointments
  # Parametros: title, description, fecha, hora_inicio, hora_fin, whatsapp_client, location
  def create
    unless required_params_present?
      render json: { 
        success: false, 
        error: 'Faltan parámetros requeridos: title, fecha, hora_inicio, hora_fin' 
      }, status: :bad_request
      return
    end

    begin
      start_datetime, end_datetime = build_datetimes
      minimum_datetime = DateTime.current + MINIMUM_ADVANCE_HOURS.hours
      raise StandardError, "La cita debe ser programada con al menos #{MINIMUM_ADVANCE_HOURS} hora(s) de anticipación" if start_datetime < minimum_datetime
      
      appointment = @current_user.appointments.build(
        title: params[:title],
        description: params[:description],
        start_datetime: start_datetime,
        end_datetime: end_datetime,
        location: params[:location],
        whatsapp_client: params[:whatsapp_client],
        status: :confirmed
      )

      if appointment.save
        render json: {
          success: true,
          message: "Cita '#{appointment.title}' agendada exitosamente para el #{appointment.formatted_datetime}",
          data: format_appointment_detailed(appointment)
        }, status: :created
      else
        render json: {
          success: false,
          error: "Error al crear la cita",
          details: appointment.errors.full_messages
        }, status: :unprocessable_entity
      end

    rescue Date::Error, ArgumentError => e
      render json: { 
        success: false,
        error: 'Error en formato de fecha u hora. Usa formato: fecha (YYYY-MM-DD), hora_inicio/hora_fin (HH:MM)',
        details: e.message
      }, status: :bad_request
    
    rescue StandardError => e
        render json: {
        success: false,
        error: "La cita debe ser programada con al menos #{MINIMUM_ADVANCE_HOURS} hora(s) de anticipación",
        details: e.message
      }, status: :bad_request  

    end
  end

  # PATCH/PUT /api/v1/appointments/:id
  def update
    begin
      start_datetime, end_datetime = build_datetimes if params[:fecha] || params[:hora_inicio] || params[:hora_fin]
      
      update_params = {
        title: params[:title],
        description: params[:description],
        location: params[:location],
        status: params[:status]
      }.compact

      update_params[:start_datetime] = start_datetime if start_datetime
      update_params[:end_datetime] = end_datetime if end_datetime

      if @appointment.update(update_params)
        render json: {
          success: true,
          message: "Cita actualizada exitosamente",
          data: format_appointment_detailed(@appointment)
        }
      else
        render json: {
          success: false,
          error: "Error al actualizar la cita",
          details: @appointment.errors.full_messages
        }, status: :unprocessable_entity
      end

    rescue Date::Error, ArgumentError => e
      render json: { 
        success: false,
        error: 'Error en formato de fecha u hora',
        details: e.message
      }, status: :bad_request
    end
  end

  # DELETE /api/v1/appointments/:id
  def destroy
    appointment_title = @appointment.title
    
    if @appointment.destroy
      render json: {
        success: true,
        message: "Cita '#{appointment_title}' cancelada exitosamente"
      }
    else
      render json: {
        success: false,
        error: "Error al cancelar la cita"
      }, status: :unprocessable_entity
    end
  end

  private

  def set_current_user_for_testing
    @current_user = User.first || User.create!(
      email: 'test@example.com',
      name: 'Test User',
      google_id: 'test123'
    )
  end

  def set_appointment
    @appointment = @current_user.appointments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { 
      success: false, 
      error: 'Cita no encontrada' 
    }, status: :not_found
  end

  def required_params_present?
    params[:title].present? && params[:fecha].present? && 
    params[:hora_inicio].present? && params[:hora_fin].present?
  end

  def build_datetimes
    fecha = Date.parse(params[:fecha])
    hora_inicio = Time.parse(params[:hora_inicio])
    hora_fin = Time.parse(params[:hora_fin])
    
    start_datetime = DateTime.new(fecha.year, fecha.month, fecha.day, hora_inicio.hour, hora_inicio.min)
    end_datetime = DateTime.new(fecha.year, fecha.month, fecha.day, hora_fin.hour, hora_fin.min)
    
    [start_datetime, end_datetime]
  end

  def build_availability_message(date, appointments, google_events)
    day_name = CalendarConfig::DAY_NAMES[date.wday]
    date_formatted = date.strftime('%d/%m/%Y')
    
    # Verificar configuración de horarios
    calendar_configs = @current_user.calendar_configs.active.where(day_of_week: date.wday)
    
    if calendar_configs.any?
      available_periods = calendar_configs.map { |config| "#{config.start_time.strftime('%H:%M')} a #{config.end_time.strftime('%H:%M')}" }.join(', ')
      availability_msg = "📅 Horarios de atención para #{day_name} #{date_formatted}: #{available_periods}"
    else
      availability_msg = "📅 No hay horarios de atención configurados para #{day_name} #{date_formatted}"
    end

    # Mostrar citas ocupadas
    if appointments.any? || google_events.any?
      occupied_slots = []
      
      appointments.active.each do |apt|
        occupied_slots << "#{apt.start_datetime.strftime('%H:%M')} a #{apt.end_datetime.strftime('%H:%M')} (#{apt.title})"
      end
      
      google_events.each do |event|
        start_time = event[:start_time].strftime('%H:%M')
        end_time = event[:end_time].strftime('%H:%M')
        occupied_slots << "#{start_time} a #{end_time} (#{event[:title]})"
      end
      
      occupied_msg = "🔴 Horarios ocupados: #{occupied_slots.join(', ')}"
    else
      occupied_msg = "✅ No hay citas programadas"
    end

    "#{availability_msg}\n\n#{occupied_msg}\n\n💡 Puedes agendar citas en los horarios de atención que no estén ocupados."
  end

  def format_appointment(appointment)
    {
      id: appointment.id,
      title: appointment.title,
      description: appointment.description,
      start_datetime: appointment.start_datetime,
      end_datetime: appointment.end_datetime,
      status: appointment.status,
      location: appointment.location,
      whatsapp_client: appointment.whatsapp_client,
      formatted_datetime: appointment.formatted_datetime
    }
  end

  def format_appointment_detailed(appointment)
    base = format_appointment(appointment)
    base[:sync_status] = appointment.calendar_syncs.map do |sync|
      {
        service: sync.service_display_name,
        status: sync.sync_status,
        external_id: sync.external_event_id,
        last_synced: sync.last_synced_at,
        error: sync.last_error
      }
    end
    base
  end

  def format_google_event(event)
    {
      title: event[:title],
      start_time: event[:start_time].strftime('%H:%M'),
      end_time: event[:end_time].strftime('%H:%M'),
      external_id: event[:external_id]
    }
  end
end