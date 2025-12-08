module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate_request, only: [:create]
      
      # POST /api/v1/login
      def create
        @user = User.find_by(email: params[:email]&.downcase)
        
        # Use constant-time comparison to prevent timing attacks
        if @user && @user.authenticate(params[:password])
          token = @user.generate_token
          render json: { 
            user: user_response(@user), 
            token: token 
          }, status: :ok
        else
          # Return the same error message regardless of whether email exists
          # and use a small delay to make timing more consistent
          sleep(0.01) unless @user
          render json: { errors: ['Invalid email or password'] }, status: :unauthorized
        end
      end
      
      # DELETE /api/v1/logout
      def destroy
        # With JWT, logout is handled client-side by removing the token
        head :no_content
      end
      
      private
      
      def user_response(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end
    end
  end
end
