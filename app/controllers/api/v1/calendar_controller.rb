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