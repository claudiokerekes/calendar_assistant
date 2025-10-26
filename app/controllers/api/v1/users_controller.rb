class Api::V1::UsersController < ApplicationController
  before_action :require_api_authentication, except: [:generate_api_token]
  before_action :authenticate_user!, only: [:generate_api_token]
  
  # GET /api/v1/users/profile
  def profile
    render json: {
      user: {
        id: @current_user.id,
        email: @current_user.email,
        name: @current_user.name,
        plan: @current_user.plan,
        whatsapp_numbers_limit: @current_user.whatsapp_numbers_limit,
        whatsapp_numbers_count: @current_user.whatsapp_numbers.active.count,
        can_add_whatsapp_number: @current_user.can_add_whatsapp_number?
      }
    }
  end
  
  # PUT /api/v1/users/profile
  def update_profile
    if @current_user.update(profile_params)
      render json: {
        user: {
          id: @current_user.id,
          email: @current_user.email,
          name: @current_user.name
        }
      }
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/users/whatsapp_numbers
  def whatsapp_numbers
    numbers = @current_user.whatsapp_numbers.includes(:user)
    
    render json: {
      whatsapp_numbers: numbers.map do |number|
        {
          id: number.id,
          phone_number: number.phone_number,
          is_active: number.is_active,
          webhook_url: number.webhook_url,
          created_at: number.created_at
        }
      end
    }
  end
  
  # POST /api/v1/users/whatsapp_numbers
  def create_whatsapp_number
    unless @current_user.can_add_whatsapp_number?
      return render json: { 
        error: "You have reached the limit of WhatsApp numbers for your #{@current_user.plan} plan" 
      }, status: :forbidden
    end
    
    whatsapp_number = @current_user.whatsapp_numbers.build(whatsapp_number_params)
    
    if whatsapp_number.save
      render json: {
        whatsapp_number: {
          id: whatsapp_number.id,
          phone_number: whatsapp_number.phone_number,
          is_active: whatsapp_number.is_active,
          webhook_url: whatsapp_number.webhook_url
        }
      }, status: :created
    else
      render json: { errors: whatsapp_number.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PUT /api/v1/users/whatsapp_numbers/:id
  def update_whatsapp_number
    whatsapp_number = @current_user.whatsapp_numbers.find(params[:id])
    
    if whatsapp_number.update(whatsapp_number_params)
      render json: {
        whatsapp_number: {
          id: whatsapp_number.id,
          phone_number: whatsapp_number.phone_number,
          is_active: whatsapp_number.is_active,
          webhook_url: whatsapp_number.webhook_url
        }
      }
    else
      render json: { errors: whatsapp_number.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'WhatsApp number not found' }, status: :not_found
  end
  
  # DELETE /api/v1/users/whatsapp_numbers/:id
  def delete_whatsapp_number
    whatsapp_number = @current_user.whatsapp_numbers.find(params[:id])
    whatsapp_number.destroy!
    
    render json: { message: 'WhatsApp number deleted successfully' }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'WhatsApp number not found' }, status: :not_found
  end
  
  # POST /api/v1/users/generate_api_token
  def generate_api_token
    user = @current_user || current_user
    
    payload = {
      user_id: user.id,
      exp: 30.days.from_now.to_i
    }
    
    token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
    
    render json: { api_token: token }
  end
  
  private
  
  def profile_params
    params.require(:user).permit(:name)
  end
  
  def whatsapp_number_params
    params.require(:whatsapp_number).permit(:phone_number, :webhook_url, :is_active)
  end
end