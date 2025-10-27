class CalendarConfigsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_calendar_config, only: [:show, :edit, :update, :destroy]

  def index
    @calendar_configs = current_user.calendar_configs.order(:day_of_week, :start_time)
    @days_with_configs = @calendar_configs.group(:day_of_week).count
  end

  def show
  end

  def new
    @calendar_config = current_user.calendar_configs.build
  end

  def create
    @calendar_config = current_user.calendar_configs.build(calendar_config_params)
    
    if @calendar_config.save
      redirect_to calendar_configs_path, notice: 'Configuración de horario creada exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @calendar_config.update(calendar_config_params)
      redirect_to calendar_configs_path, notice: 'Configuración actualizada exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @calendar_config.destroy
    redirect_to calendar_configs_path, notice: 'Configuración eliminada exitosamente.'
  end

  # Acción para configurar todos los días de la semana de una vez
  def bulk_create
    days = params[:days] || []
    start_time = params[:start_time]
    end_time = params[:end_time]
    notes = params[:notes]
    
    created_count = 0
    errors = []

    days.each do |day_of_week|
      # Eliminar configuraciones existentes para este día
      current_user.calendar_configs.where(day_of_week: day_of_week).destroy_all
      
      config = current_user.calendar_configs.build(
        day_of_week: day_of_week.to_i,
        start_time: start_time,
        end_time: end_time,
        is_active: true,
        notes: notes
      )
      
      if config.save
        created_count += 1
      else
        errors << "#{CalendarConfig::DAY_NAMES[day_of_week.to_i]}: #{config.errors.full_messages.join(', ')}"
      end
    end

    if errors.empty?
      redirect_to calendar_configs_path, notice: "#{created_count} configuración(es) creada(s) exitosamente."
    else
      redirect_to calendar_configs_path, alert: "Errores: #{errors.join('; ')}"
    end
  end

  # Acción para activar/desactivar rápidamente
  def toggle_active
    @calendar_config = current_user.calendar_configs.find(params[:id])
    @calendar_config.update(is_active: !@calendar_config.is_active)
    
    respond_to do |format|
      format.json { render json: { success: true, is_active: @calendar_config.is_active } }
      format.html { redirect_to calendar_configs_path }
    end
  end

  private

  def set_calendar_config
    @calendar_config = current_user.calendar_configs.find(params[:id])
  end

  def calendar_config_params
    params.require(:calendar_config).permit(:day_of_week, :start_time, :end_time, :is_active, :notes)
  end
end