# Inicializador para el sistema de observers de calendario
Rails.application.configure do
  # Registrar el observer después de que todas las clases se hayan cargado
  config.after_initialize do
    # Solo inicializar si las clases están definidas
    if defined?(Appointment) && defined?(CalendarSyncObserver)
      # Crear instancia del observer
      calendar_observer = CalendarSyncObserver.new
      
      # Registrar el observer con el modelo Appointment
      Appointment.add_observer(calendar_observer)
      
      # Guardar referencia para uso posterior si es necesario
      Rails.application.config.calendar_observer = calendar_observer
      
      Rails.logger.info("Calendar sync observer registered successfully")
    else
      Rails.logger.warn("Could not initialize calendar observer - classes not defined")
    end
  end
end