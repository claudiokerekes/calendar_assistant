module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :authenticate_request, only: [:create]
      before_action :set_user, only: [:show, :update, :destroy]
      
      # POST /api/v1/signup
      def create
        @user = User.new(user_params)
        
        if @user.save
          token = @user.generate_token
          render json: { 
            user: user_response(@user), 
            token: token 
          }, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/users/:id
      def show
        render json: { user: user_response(@user) }
      end
      
      # PATCH/PUT /api/v1/users/:id
      def update
        if @user.update(user_update_params)
          render json: { user: user_response(@user) }
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/users/:id
      def destroy
        @user.destroy
        head :no_content
      end
      
      private
      
      def set_user
        @user = User.find(params[:id])
        unless @user.id == current_user.id
          render json: { errors: ['Forbidden'] }, status: :forbidden
        end
      end
      
      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      end
      
      def user_update_params
        params.require(:user).permit(:name, :email)
      end
      
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
