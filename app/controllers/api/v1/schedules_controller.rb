module Api
  module V1
    class SchedulesController < ApplicationController
      before_action :set_calendar, only: [:create], if: -> { params[:calendar_id].present? }
      before_action :set_schedule, only: [:show, :update, :destroy]
      
      # GET /api/v1/schedules or /api/v1/calendars/:calendar_id/schedules
      def index
        if params[:calendar_id]
          calendar = current_user.calendars.find(params[:calendar_id])
          @schedules = calendar.schedules
        else
          @schedules = current_user.schedules
        end
        
        # Optional filtering (mutually exclusive)
        if params[:upcoming] == 'true'
          @schedules = @schedules.upcoming
        elsif params[:past] == 'true'
          @schedules = @schedules.past
        end
        
        @schedules = @schedules.on_date(params[:date]) if params[:date].present?
        
        render json: { schedules: @schedules.map { |s| schedule_response(s) } }
      end
      
      # GET /api/v1/schedules/:id or /api/v1/calendars/:calendar_id/schedules/:id
      def show
        render json: { schedule: schedule_response(@schedule) }
      end
      
      # POST /api/v1/calendars/:calendar_id/schedules
      def create
        @schedule = @calendar.schedules.build(schedule_params)
        
        if @schedule.save
          render json: { schedule: schedule_response(@schedule) }, status: :created
        else
          render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # PATCH/PUT /api/v1/schedules/:id
      def update
        if @schedule.update(schedule_params)
          render json: { schedule: schedule_response(@schedule) }
        else
          render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/schedules/:id
      def destroy
        @schedule.destroy
        head :no_content
      end
      
      private
      
      def set_calendar
        @calendar = current_user.calendars.find(params[:calendar_id])
      rescue ActiveRecord::RecordNotFound
        render json: { errors: ['Calendar not found'] }, status: :not_found
      end
      
      def set_schedule
        @schedule = current_user.schedules.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { errors: ['Schedule not found'] }, status: :not_found
      end
      
      def schedule_params
        params.require(:schedule).permit(:title, :description, :start_time, :end_time, :location, :all_day)
      end
      
      def schedule_response(schedule)
        {
          id: schedule.id,
          title: schedule.title,
          description: schedule.description,
          start_time: schedule.start_time,
          end_time: schedule.end_time,
          location: schedule.location,
          all_day: schedule.all_day,
          calendar_id: schedule.calendar_id,
          created_at: schedule.created_at,
          updated_at: schedule.updated_at
        }
      end
    end
  end
end
