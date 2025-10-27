class Api::V1::CalendarController < ApplicationController
  before_action :require_api_authentication
  before_action :ensure_google_calendar_access
  
  # GET /api/v1/calendar/events?date=2023-10-24
  def events
    date = Date.parse(params[:date]) rescue Date.current
    start_time = date.beginning_of_day.iso8601
    end_time = date.end_of_day.iso8601
    
    begin
      events = @current_user.google_calendar_service.list_events(
        'primary',
        time_min: start_time,
        time_max: end_time,
        single_events: true,
        order_by: 'startTime'
      )
      
      formatted_events = events.items.map do |event|
        {
          id: event.id,
          summary: event.summary,
          description: event.description,
          start_time: event.start&.date_time || event.start&.date,
          end_time: event.end&.date_time || event.end&.date,
          location: event.location,
          attendees: event.attendees&.map { |a| { email: a.email, name: a.display_name } }
        }
      end
      
      render json: { events: formatted_events }
    rescue Google::Apis::AuthorizationError
      render json: { error: 'Calendar access denied. Please re-authenticate.' }, status: :unauthorized
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end
  
  # POST /api/v1/calendar/events
  def create_event
    begin
      event = Google::Apis::CalendarV3::Event.new(
        summary: params[:summary],
        description: params[:description],
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: DateTime.parse(params[:start_time])
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: DateTime.parse(params[:end_time])
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
        event: {
          id: created_event.id,
          summary: created_event.summary,
          description: created_event.description,
          start_time: created_event.start.date_time,
          end_time: created_event.end.date_time,
          location: created_event.location,
          html_link: created_event.html_link
        }
      }, status: :created
    rescue Google::Apis::AuthorizationError
      render json: { error: 'Calendar access denied. Please re-authenticate.' }, status: :unauthorized
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
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
  
  private
  
  def ensure_google_calendar_access
    unless @current_user.access_token
      render json: { error: 'Google Calendar not connected. Please authenticate.' }, status: :unauthorized
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

  private

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