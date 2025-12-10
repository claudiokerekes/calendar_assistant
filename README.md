# Calendar Assistant 📅🤖

Una plataforma SaaS que permite gestionar tu Google Calendar a través de WhatsApp con inteligencia artificial.

## ✨ Características

- 🔐 **Autenticación con Google OAuth 2.0**
- 📅 **Integración completa con Google Calendar**
- 🤖 **Asistente AI inteligente para WhatsApp**
- 📱 **Gestión de múltiples números de WhatsApp**
- 🔒 **API segura con autenticación JWT**
- 💼 **Sistema de planes y licencias**
- 🌐 **Interfaz web completa**

## 🚀 Funcionalidades

### Para Usuarios
- Login con Google y acceso automático al calendario
- Gestión de números de WhatsApp
- Dashboard con estadísticas y configuración
- Generación de tokens API

### API de Calendar
- `GET /api/v1/calendar/events` - Consultar eventos por fecha
- `POST /api/v1/calendar/events` - Crear nuevos eventos
- `PUT /api/v1/calendar/events/:id` - Actualizar eventos
- `DELETE /api/v1/calendar/events/:id` - Eliminar eventos
- `GET /api/v1/calendar/availability` - Consultar disponibilidad

### WhatsApp AI Assistant
- Consulta de agenda diaria
- Creación de citas mediante lenguaje natural
- Búsqueda de horarios disponibles
- Webhooks personalizables

## 🛠️ Instalación

### Prerrequisitos
- Ruby 3.0+
- Rails 7.2+
- PostgreSQL
- Cuenta de Google Cloud Platform
- Proveedor de WhatsApp API (Twilio, Meta, etc.)


### Configuración

1. **Clona el repositorio**
```bash
git clone <repository-url>
cd calendar_assistant
```

2. **Instala las dependencias**
```bash
bundle install
```

3. **Configura la base de datos**
```bash
rails db:create
rails db:migrate
```

4. **Configura las variables de entorno**
```bash
cp .env.example .env
```

Edita `.env` con tus credenciales:
```env
GOOGLE_CLIENT_ID=tu_google_client_id
GOOGLE_CLIENT_SECRET=tu_google_client_secret
WHATSAPP_VERIFY_TOKEN=tu_token_de_verificacion
SECRET_KEY_BASE=rails_secret_generado
```

5. **Genera el secret key**
```bash
rails secret
```

### Configuración de Google OAuth

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita las APIs:
   - Google Calendar API
   - Google+ API
4. Crea credenciales OAuth 2.0:
   - Tipo: Web application
   - URIs de redirección autorizadas: `http://localhost:3000/auth/google_oauth2/callback`
5. Copia el Client ID y Client Secret a tu archivo `.env`

### Configuración de WhatsApp

Elige tu proveedor de WhatsApp API y configura el webhook:

**URL del Webhook:** `https://tu-dominio.com/api/v1/whatsapp/webhook/+NUMERO_TELEFONO`

**Ejemplo con Twilio:**
1. Crea una cuenta en Twilio
2. Configura WhatsApp Sandbox
3. Configura el webhook URL
4. Usa el token de verificación de tu `.env`

## 🏃‍♂️ Uso

### Iniciar el servidor
```bash
rails server
```

### Acceder a la aplicación
1. Ve a `http://localhost:3000`
2. Haz clic en "Iniciar sesión con Google"
3. Autoriza el acceso a tu calendario
4. Configura tu número de WhatsApp en el dashboard

### Usar la API

#### Generar Token
```bash
curl -X POST http://localhost:3000/api/v1/users/generate_api_token \
  -H "X-CSRF-Token: tu-csrf-token"
```

#### Consultar eventos
```bash
curl -X GET "http://localhost:3000/api/v1/calendar/events?date=2023-10-24" \
  -H "Authorization: Bearer tu-token-jwt"
```

#### Crear evento
```bash
curl -X POST http://localhost:3000/api/v1/calendar/events \
  -H "Authorization: Bearer tu-token-jwt" \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "Reunión importante",
    "description": "Reunión con el equipo",
    "start_time": "2023-10-24T14:00:00Z",
    "end_time": "2023-10-24T15:00:00Z",
    "location": "Oficina principal"
  }'
```

## 📱 Uso de WhatsApp

Una vez configurado tu número, puedes enviar mensajes como:

- "¿Cómo está mi agenda hoy?"
- "¿Estoy libre mañana a las 3 PM?"
- "Agenda una reunión con Juan para el viernes"
- "Muéstrame mi calendario de esta semana"

## 💰 Planes y Licencias

### Plan Básico (Gratis)
- 1 número de WhatsApp
- Funciones básicas de calendario
- Soporte por email

### Plan Premium ($19/mes)
- 5 números de WhatsApp
- AI avanzada
- Recordatorios automáticos
- Soporte prioritario

### Plan Empresarial ($99/mes)
- Números ilimitados
- API completa
- Webhooks personalizados
- Soporte dedicado

## 🔧 Estructura del Proyecto

```
app/
├── controllers/
│   ├── api/v1/
│   │   ├── calendar_controller.rb    # API de Google Calendar
│   │   ├── users_controller.rb       # Gestión de usuarios
│   │   └── whatsapp_controller.rb    # Webhooks de WhatsApp
│   ├── dashboard_controller.rb       # Dashboard principal
│   ├── home_controller.rb            # Página principal
│   └── sessions_controller.rb        # Autenticación OAuth
├── models/
│   ├── user.rb                       # Modelo de usuario
│   └── whatsapp_number.rb           # Números de WhatsApp
└── views/
    ├── dashboard/                    # Vistas del dashboard
    ├── home/                         # Página principal
    └── sessions/                     # Login/logout
```

## 🚀 Despliegue

### Heroku
```bash
heroku create tu-app-calendar-assistant
heroku addons:create heroku-postgresql:hobby-dev
heroku config:set GOOGLE_CLIENT_ID=tu_client_id
heroku config:set GOOGLE_CLIENT_SECRET=tu_client_secret
heroku config:set WHATSAPP_VERIFY_TOKEN=tu_token
git push heroku main
heroku run rails db:migrate
```

### Docker
```bash
docker build -t calendar-assistant .
docker run -p 3000:3000 calendar-assistant
```

## 📚 API Documentation

### Autenticación
Todas las peticiones a la API requieren un token JWT en el header:
```
Authorization: Bearer YOUR_JWT_TOKEN
```

### Endpoints Principales

#### Calendar API
- `GET /api/v1/calendar/events?date=YYYY-MM-DD` - Listar eventos
- `POST /api/v1/calendar/events` - Crear evento
- `PUT /api/v1/calendar/events/:id` - Actualizar evento
- `DELETE /api/v1/calendar/events/:id` - Eliminar evento
- `GET /api/v1/calendar/availability?date=YYYY-MM-DD&duration=60` - Disponibilidad

#### Users API
- `GET /api/v1/users/profile` - Perfil del usuario
- `PUT /api/v1/users/profile` - Actualizar perfil
- `GET /api/v1/users/whatsapp_numbers` - Listar números WhatsApp
- `POST /api/v1/users/whatsapp_numbers` - Agregar número WhatsApp
- `POST /api/v1/users/generate_api_token` - Generar token API

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto está bajo la licencia MIT. Ver `LICENSE` para más detalles.

## 🆘 Soporte

- 📧 Email: soporte@calendar-assistant.com
- 📖 Documentación: [docs.calendar-assistant.com](https://docs.calendar-assistant.com)
- 🐛 Issues: [GitHub Issues](https://github.com/tu-usuario/calendar-assistant/issues)

## 🔮 Próximas Funcionalidades

- [ ] Integración con Microsoft Calendar
- [ ] Recordatorios automáticos por WhatsApp
- [ ] Análisis y reportes de productividad
- [ ] Integración con Zoom/Meet para videollamadas
- [ ] Soporte para múltiples idiomas
- [ ] App móvil nativa
