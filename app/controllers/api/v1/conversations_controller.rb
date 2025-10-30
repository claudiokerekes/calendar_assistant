class Api::V1::ConversationsController < ApplicationController
  skip_before_action :verify_authenticity_token # Skip CSRF for API endpoints
  
  # POST /api/v1/conversations/message
  # Parametros: user_id, whatsapp_client, message_client, user_type, prompt_tokens (opcional), completion_tokens (opcional)
  def create_message
    begin
      user = User.find(params[:user_id])
      
      # Buscar o crear la conversación
      conversation = user.conversations.find_or_create_by(whatsapp_client: params[:whatsapp_client])
      
      # Crear el mensaje
      message = conversation.messages.create!(
        message_content: params[:message_client],
        user_type: params[:user_type], # 'user' o 'system'
        prompt_tokens: params[:prompt_tokens],
        completion_tokens: params[:completion_tokens]
      )
      
      render json: {
        success: true,
        data: {
          conversation_id: conversation.id,
          message_id: message.id,
          whatsapp_client: conversation.whatsapp_client,
          message_content: message.message_content,
          user_type: message.user_type,
          prompt_tokens: message.prompt_tokens,
          completion_tokens: message.completion_tokens,
          created_at: message.created_at
        }
      }, status: :created
      
    rescue ActiveRecord::RecordNotFound => e
      render json: { 
        success: false,
        error: "Usuario no encontrado" 
      }, status: :not_found
      
    rescue ActiveRecord::RecordInvalid => e
      render json: { 
        success: false,
        error: "Error de validación",
        details: e.record.errors.full_messages
      }, status: :unprocessable_entity
      
    rescue StandardError => e
      render json: { 
        success: false,
        error: e.message 
      }, status: :internal_server_error
    end
  end
  
  # GET /api/v1/conversations/context?user_id=1&whatsapp_client=+1234567890
  # Devuelve los últimos mensajes para contexto del LLM (excluyendo el último mensaje que ya está en n8n)
  def get_context
    begin
      user = User.find(params[:user_id])
      conversation = user.conversations.find_by(whatsapp_client: params[:whatsapp_client])
      
      if conversation.nil?
        render json: {
          success: true,
          data: {
            conversation_exists: false,
            whatsapp_client: params[:whatsapp_client],
            messages: []
          }
        }
        return
      end
      
      # Obtener los últimos 5 mensajes y excluir el más reciente (ya está en n8n)
      all_messages = conversation.latest_messages(5)
      messages = all_messages[0..-2] # Excluir el último mensaje
      
      formatted_messages = messages.map do |message|
        {
       #   id: message.id,
          message_content: message.message_content,
          user_type: message.user_type,
         # prompt_tokens: message.prompt_tokens,
         # completion_tokens: message.completion_tokens,
        # created_at: message.created_at
        }
      end
      
      render json: {
        success: true,
        data: {
          conversation_exists: true,
          conversation_id: conversation.id,
          whatsapp_client: conversation.whatsapp_client,
          total_messages: conversation.messages.count,
          context_messages: formatted_messages
        }
      }
      
    rescue ActiveRecord::RecordNotFound => e
      render json: { 
        success: false,
        error: "Usuario no encontrado" 
      }, status: :not_found
      
    rescue StandardError => e
      render json: { 
        success: false,
        error: e.message 
      }, status: :internal_server_error
    end  
  end
  
  private
  
  def message_params
    params.permit(:user_id, :whatsapp_client, :message_client, :user_type, :prompt_tokens, :completion_tokens)
  end
end
