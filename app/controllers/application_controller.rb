class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :authenticate_user!, except: [:index, :show, :new, :create]
  
  private
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def authenticate_user!
    unless current_user
      redirect_to login_path, alert: 'Please log in to continue.'
    end
  end
  
  def require_api_authentication
    token = request.headers['Authorization']&.gsub('Bearer ', '')
    
    unless token
      render json: { error: 'Authentication token required' }, status: :unauthorized
      return
    end
    
    begin
      decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256')
      user_id = decoded_token[0]['user_id']
      @current_user = User.find(user_id)
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: 'Invalid authentication token' }, status: :unauthorized
    end
  end
  
  helper_method :current_user
end
