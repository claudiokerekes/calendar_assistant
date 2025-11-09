class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:omniauth_callback]
  protect_from_forgery with: :exception, except: [:omniauth_callback]
  
  def new
    # Página de login
  end

  def omniauth_callback
    user = User.from_omniauth(request.env['omniauth.auth'])
    
    if user.persisted?
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: 'Login exitoso!'
    else
      redirect_to login_path, alert: 'Error en el login'
    end
  rescue => e
    Rails.logger.error "OAuth Error: #{e.message}"
    redirect_to login_path, alert: 'Error en la autenticación'
  end

  def omniauth
    user = User.from_omniauth(request.env['omniauth.auth'])
    if user.persisted?
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: 'Successfully logged in with Google!'
    else
      redirect_to login_path, alert: 'There was an error logging you in.'
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'Successfully logged out!'
  end

  def failure
    redirect_to login_path, alert: 'Authentication failed.'
  end
end