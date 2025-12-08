module Api
  module V1
    class CalendarsController < ApplicationController
      before_action :set_calendar, only: [:show, :update, :destroy]
      
      # GET /api/v1/calendars
      def index
        @calendars = current_user.calendars
        render json: { calendars: @calendars.map { |c| calendar_response(c) } }
      end
      
      # GET /api/v1/calendars/:id
      def show
        render json: { calendar: calendar_response(@calendar) }
      end
      
      # POST /api/v1/calendars
      def create
        @calendar = current_user.calendars.build(calendar_params)
        
        if @calendar.save
          render json: { calendar: calendar_response(@calendar) }, status: :created
        else
          render json: { errors: @calendar.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # PATCH/PUT /api/v1/calendars/:id
      def update
        if @calendar.update(calendar_params)
          render json: { calendar: calendar_response(@calendar) }
        else
          render json: { errors: @calendar.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/calendars/:id
      def destroy
        @calendar.destroy
        head :no_content
      end
      
      private
      
      def set_calendar
        @calendar = current_user.calendars.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { errors: ['Calendar not found'] }, status: :not_found
      end
      
      def calendar_params
        params.require(:calendar).permit(:name, :description, :timezone, :color)
      end
      
      def calendar_response(calendar)
        {
          id: calendar.id,
          name: calendar.name,
          description: calendar.description,
          timezone: calendar.timezone,
          color: calendar.color,
          user_id: calendar.user_id,
          created_at: calendar.created_at,
          updated_at: calendar.updated_at
        }
      end
    end
  end
end
