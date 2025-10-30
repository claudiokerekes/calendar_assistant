class Api::V1::WhatsappController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  # GET /api/v1/whatsapp/user_by_phone?phone_number=+573001234567
  def user_by_phone
    phone_number = params[:phone_number]
    
    if phone_number.blank?
      return render json: { 
        success: false,
        error: 'Phone number parameter is required' 
      }, status: :bad_request
    end
    
    whatsapp_number = WhatsappNumber.active.find_by(phone_number: phone_number)
    
    if whatsapp_number
      render json: {
        success: true,
        data: {
          user_id: whatsapp_number.user.id,
          user_name: whatsapp_number.user.name,
          user_email: whatsapp_number.user.email,
          phone_number: whatsapp_number.phone_number,
          is_active: whatsapp_number.is_active
        }
      }
    else
      render json: {
        success: false,
        error: 'WhatsApp number not found or inactive',
        data: {
          phone_number: phone_number,
          user_id: nil
        }
      }, status: :not_found
    end
  end
  
end