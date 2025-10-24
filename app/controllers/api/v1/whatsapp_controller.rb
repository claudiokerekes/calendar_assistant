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
    
    # Parse WhatsApp message
    message_data = parse_whatsapp_message(request.body.read)
    
    if message_data
      Rails.logger.info "Received WhatsApp message: #{message_data.inspect}"
      
      # Return the parsed message data for external processing (n8n, etc.)
      render json: { 
        status: 'ok',
        user_id: whatsapp_number.user.id,
        phone_number: phone_number,
        message: message_data 
      }
    else
      render json: { status: 'ok', message: 'No valid message data found' }
    end
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
end