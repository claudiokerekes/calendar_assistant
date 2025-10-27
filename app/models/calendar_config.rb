class CalendarConfig < ApplicationRecord
  belongs_to :user

  # Constantes para días de la semana (0 = Domingo, 1 = Lunes, etc.)
  DAYS_OF_WEEK = {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }.freeze

  DAY_NAMES = {
    0 => 'Domingo',
    1 => 'Lunes',
    2 => 'Martes',
    3 => 'Miércoles',
    4 => 'Jueves',
    5 => 'Viernes',
    6 => 'Sábado'
  }.freeze

  # Validaciones
  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :is_active, inclusion: { in: [true, false] }
  validate :end_time_after_start_time

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :by_day, ->(day) { where(day_of_week: day) }
  scope :for_weekdays, -> { where(day_of_week: 1..5) }
  scope :for_weekends, -> { where(day_of_week: [0, 6]) }

  # Métodos de instancia
  def day_name
    DAY_NAMES[day_of_week]
  end

  def formatted_start_time
    start_time.strftime('%H:%M')
  end

  def formatted_end_time
    end_time.strftime('%H:%M')
  end

  def formatted_time_range
    "#{formatted_start_time} - #{formatted_end_time}"
  end

  def duration_in_hours
    return 0 unless start_time && end_time
    
    # Convertir a segundos y luego a horas
    ((end_time - start_time) / 1.hour).round(2)
  end

  # Verifica si una hora específica está dentro del rango
  def includes_time?(time)
    return false unless start_time && end_time
    
    time_of_day = time.strftime('%H:%M:%S')
    start_str = start_time.strftime('%H:%M:%S')
    end_str = end_time.strftime('%H:%M:%S')
    
    time_of_day >= start_str && time_of_day <= end_str
  end

  private

  def end_time_after_start_time
    return unless start_time && end_time
    
    if end_time <= start_time
      errors.add(:end_time, 'debe ser posterior a la hora de inicio')
    end
  end
end
