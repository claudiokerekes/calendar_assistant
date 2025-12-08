class ApplicationController < ActionController::API
  before_action :authenticate_request
  
  attr_reader :current_user
  
  private
  
  def authenticate_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    
    begin
      decoded = JWT.decode(token, Rails.application.secret_key_base).first
      @current_user = User.find(decoded['user_id'])
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError, JWT::ExpiredSignature
      render json: { errors: ['Unauthorized'] }, status: :unauthorized
    end
  end
  
  def authorize_resource_owner(resource)
    unless resource.user_id == current_user.id
      render json: { errors: ['Forbidden'] }, status: :forbidden
    end
  end
end
