class Api::V1::WhatsappController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_webhook_signature, only: [:webhook]
  
  # POST /api/v1/whatsapp/webhook/:phone_number
  def webhook
    phone_number = params[:phone_number]
    whatsapp_number = WhatsappNumber.active.find_by(phone_number: phone_number)
    
    unless whatsapp_number
      return render json: { error: 'WhatsApp number not found or inactive' }, status: :not_found
    end
    
    # Process WhatsApp message
    message_data = parse_whatsapp_message(request.body.read)
    
    if message_data
      # Here you would integrate with your AI agent
      # For now, let's just log the message and send a simple response
      Rails.logger.info "Received WhatsApp message: #{message_data.inspect}"
      
      # Process the message with AI agent
      response = process_with_ai_agent(message_data, whatsapp_number.user)
      
      # Send response back to WhatsApp (implementation depends on your WhatsApp API provider)
      send_whatsapp_response(phone_number, response)
    end
    
    render json: { status: 'ok' }
  end
  
  # GET /api/v1/whatsapp/webhook/:phone_number (for webhook verification)
  def verify_webhook
    # WhatsApp webhook verification
    challenge = params['hub.challenge']
    verify_token = params['hub.verify_token']
    
    # You should set this token in your WhatsApp webhook configuration
    expected_token = ENV['WHATSAPP_VERIFY_TOKEN']
    
    if verify_token == expected_token
      render plain: challenge
    else
      render json: { error: 'Invalid verify token' }, status: :forbidden
    end
  end
  
  private
  
  def verify_webhook_signature
    # Implement webhook signature verification based on your WhatsApp API provider
    # This is important for security
    signature = request.headers['X-Hub-Signature-256']
    
    if signature.blank?
      Rails.logger.warn "Missing webhook signature"
      # For development, we'll allow requests without signature
      return true if Rails.env.development?
      
      render json: { error: 'Missing signature' }, status: :unauthorized
      return false
    end
    
    # Verify signature logic here
    # expected_signature = OpenSSL::HMAC.hexdigest('sha256', webhook_secret, request.body.read)
    # unless Rack::Utils.secure_compare(signature, "sha256=#{expected_signature}")
    #   render json: { error: 'Invalid signature' }, status: :unauthorized
    #   return false
    # end
    
    true
  end
  
  def parse_whatsapp_message(body)
    begin
      data = JSON.parse(body)
      
      # Parse WhatsApp webhook format (this varies by provider)
      # This is a generic example - adjust based on your WhatsApp API provider
      if data['entry']&.first&.dig('changes')&.first&.dig('value', 'messages')&.first
        message = data['entry'].first['changes'].first['value']['messages'].first
        {
          from: message['from'],
          text: message['text']&.dig('body'),
          timestamp: message['timestamp'],
          message_id: message['id']
        }
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse WhatsApp message: #{e.message}"
      nil
    end
  end
  
  def process_with_ai_agent(message_data, user)
    # This is where you'd integrate with your AI agent
    # For now, let's return a simple calendar-related response
    
    text = message_data[:text]&.downcase
    
    case text
    when /agenda|cita|reunión|appointment|meeting/
      "¡Hola! 👋 Soy tu asistente de calendario. Puedo ayudarte a:\n\n" +
      "📅 Ver tu agenda de hoy\n" +
      "➕ Crear nuevas citas\n" +
      "🔍 Buscar horarios disponibles\n" +
      "🗓️ Gestionar tus eventos\n\n" +
      "¿En qué te puedo ayudar?"
      
    when /hoy|today|agenda|calendario/
      # Get today's events
      get_todays_agenda(user)
      
    when /mañana|tomorrow/
      # Get tomorrow's events
      get_agenda_for_date(user, Date.tomorrow)
      
    when /disponible|available|libre|free|horario/
      "🕐 Para consultar tu disponibilidad, por favor especifica:\n\n" +
      "📅 Fecha (ej: mañana, 25 de octubre)\n" +
      "⏰ Duración aproximada (ej: 1 hora)\n\n" +
      "Ejemplo: '¿Estoy libre mañana por la tarde para una reunión de 1 hora?'"
      
    when /crear|agendar|programar/
      "📝 Para crear una nueva cita, proporciona:\n\n" +
      "📅 Fecha y hora\n" +
      "👥 Con quién te reunirás\n" +
      "📍 Ubicación (opcional)\n" +
      "⏱️ Duración estimada\n\n" +
      "Ejemplo: 'Agenda una reunión con María mañana a las 3 PM en la oficina'"
      
    when /ayuda|help|comandos/
      "🤖 **Comandos disponibles:**\n\n" +
      "📅 `agenda hoy` - Ver eventos de hoy\n" +
      "📅 `agenda mañana` - Ver eventos de mañana\n" +
      "🔍 `disponible [fecha]` - Ver horarios libres\n" +
      "➕ `agendar [detalles]` - Crear nueva cita\n" +
      "❌ `cancelar [evento]` - Cancelar evento\n" +
      "🆘 `ayuda` - Ver este mensaje\n\n" +
      "¡Habla de forma natural! Entiendo lenguaje cotidiano 😊"
      
    else
      "👋 ¡Hola! Soy tu asistente de calendario inteligente. " +
      "Puedo ayudarte con tu agenda de Google Calendar.\n\n" +
      "Prueba preguntarme:\n" +
      "• '¿Cómo está mi agenda hoy?'\n" +
      "• '¿Estoy libre mañana a las 3 PM?'\n" +
      "• 'Agenda una reunión con Juan'\n" +
      "• 'Ayuda' para ver todos los comandos\n\n" +
      "¡Habla conmigo de forma natural! 😊"
    end
  end
  
  def get_todays_agenda(user)
    begin
      today = Date.current
      events = user.google_calendar_service.list_events(
        'primary',
        time_min: today.beginning_of_day.iso8601,
        time_max: today.end_of_day.iso8601,
        single_events: true,
        order_by: 'startTime'
      )
      
      if events.items.any?
        response = "📅 **Tu agenda para hoy (#{today.strftime('%d/%m/%Y')}):**\n\n"
        events.items.each_with_index do |event, index|
          start_time = event.start.date_time&.strftime('%H:%M') || 'Todo el día'
          location = event.location ? " 📍 #{event.location}" : ""
          response += "#{index + 1}. **#{start_time}** - #{event.summary}#{location}\n"
        end
        response += "\n¿Necesitas hacer algún cambio? 🤔"
        response
      else
        "📅 **¡Tu agenda está libre hoy!** #{Date.current.strftime('%d/%m/%Y')}\n\n" +
        "Perfecto para planificar algo nuevo 😊\n" +
        "¿Quieres agendar alguna reunión?"
      end
    rescue StandardError => e
      Rails.logger.error "Error fetching today's agenda: #{e.message}"
      "😅 Lo siento, no pude acceder a tu calendario en este momento.\n" +
      "Error: #{e.message}\n\n" +
      "¿Podrías intentar de nuevo en unos minutos?"
    end
  end
  
  def get_agenda_for_date(user, date)
    begin
      events = user.google_calendar_service.list_events(
        'primary',
        time_min: date.beginning_of_day.iso8601,
        time_max: date.end_of_day.iso8601,
        single_events: true,
        order_by: 'startTime'
      )
      
      if events.items.any?
        response = "📅 **Tu agenda para #{date.strftime('%d/%m/%Y')}:**\n\n"
        events.items.each_with_index do |event, index|
          start_time = event.start.date_time&.strftime('%H:%M') || 'Todo el día'
          location = event.location ? " 📍 #{event.location}" : ""
          response += "#{index + 1}. **#{start_time}** - #{event.summary}#{location}\n"
        end
        response += "\n¿Necesitas hacer algún cambio? 🤔"
        response
      else
        "📅 **¡Tienes el día libre!** #{date.strftime('%d/%m/%Y')}\n\n" +
        "Perfecto para planificar algo 😊\n" +
        "¿Quieres agendar alguna reunión para ese día?"
      end
    rescue StandardError => e
      Rails.logger.error "Error fetching agenda for #{date}: #{e.message}"
      "😅 Lo siento, no pude acceder a tu calendario para esa fecha.\n" +
      "Error: #{e.message}\n\n" +
      "¿Podrías intentar de nuevo?"
    end
  end
  
  def send_whatsapp_response(phone_number, message)
    # This would integrate with your WhatsApp API provider
    # Implementation depends on the provider (Twilio, WhatsApp Business API, etc.)
    Rails.logger.info "📱 Sending WhatsApp response to #{phone_number}:"
    Rails.logger.info "📝 Message: #{message}"
    
    # Example for Twilio WhatsApp API:
    # require 'twilio-ruby'
    # client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    # client.messages.create(
    #   from: 'whatsapp:+14155238886',
    #   to: "whatsapp:#{phone_number}",
    #   body: message
    # )
    
    # Example for Meta WhatsApp Cloud API:
    # uri = URI("https://graph.facebook.com/v17.0/#{ENV['WHATSAPP_PHONE_NUMBER_ID']}/messages")
    # http = Net::HTTP.new(uri.host, uri.port)
    # http.use_ssl = true
    # 
    # request = Net::HTTP::Post.new(uri)
    # request['Authorization'] = "Bearer #{ENV['WHATSAPP_ACCESS_TOKEN']}"
    # request['Content-Type'] = 'application/json'
    # request.body = {
    #   messaging_product: 'whatsapp',
    #   to: phone_number,
    #   text: { body: message }
    # }.to_json
    # 
    # response = http.request(request)
    # Rails.logger.info "WhatsApp API response: #{response.body}"
  end
end