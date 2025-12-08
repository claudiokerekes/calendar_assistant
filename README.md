# Calendar Assistant

A Ruby on Rails SaaS application providing API endpoints for managing calendars and schedules. Built to support n8n workflows and other automation tools.

## Features

- **User Authentication**: JWT-based authentication system
- **Multi-tenant SaaS**: Each user has isolated calendars and schedules
- **RESTful API**: Full CRUD operations for calendars and schedules
- **n8n Integration**: CORS-enabled API endpoints for easy integration with n8n workflows
- **Flexible Scheduling**: Support for all-day events, timezones, and recurring schedules

## Tech Stack

- Ruby 3.2.3
- Rails 7.1
- SQLite (development/test) / PostgreSQL (production-ready)
- JWT for authentication
- RSpec for testing

## Getting Started

### Prerequisites

- Ruby 3.2.3
- Bundler

### Installation

1. Clone the repository:
```bash
git clone https://github.com/claudiokerekes/calendar_assistant.git
cd calendar_assistant
```

2. Install dependencies:
```bash
bundle install
```

3. Setup database:
```bash
rails db:create db:migrate
```

4. Start the server:
```bash
rails server
```

The API will be available at `http://localhost:3000`

## API Documentation

### Authentication

#### Sign Up
```
POST /api/v1/signup
Content-Type: application/json

{
  "user": {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

Response:
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "created_at": "2024-12-08T12:00:00.000Z",
    "updated_at": "2024-12-08T12:00:00.000Z"
  },
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

#### Login
```
POST /api/v1/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

#### Logout
```
DELETE /api/v1/logout
Authorization: Bearer <token>
```

### Calendars

All calendar endpoints require authentication via the `Authorization: Bearer <token>` header.

#### List Calendars
```
GET /api/v1/calendars
Authorization: Bearer <token>
```

#### Create Calendar
```
POST /api/v1/calendars
Authorization: Bearer <token>
Content-Type: application/json

{
  "calendar": {
    "name": "Work Calendar",
    "description": "My work schedule",
    "timezone": "America/New_York",
    "color": "#FF5733"
  }
}
```

#### Get Calendar
```
GET /api/v1/calendars/:id
Authorization: Bearer <token>
```

#### Update Calendar
```
PATCH /api/v1/calendars/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "calendar": {
    "name": "Updated Calendar Name"
  }
}
```

#### Delete Calendar
```
DELETE /api/v1/calendars/:id
Authorization: Bearer <token>
```

### Schedules

#### List Schedules
```
GET /api/v1/schedules
GET /api/v1/calendars/:calendar_id/schedules
Authorization: Bearer <token>

Query parameters:
- upcoming=true (filter upcoming schedules)
- past=true (filter past schedules)
- date=2024-12-08 (filter by specific date)
```

#### Create Schedule
```
POST /api/v1/calendars/:calendar_id/schedules
Authorization: Bearer <token>
Content-Type: application/json

{
  "schedule": {
    "title": "Team Meeting",
    "description": "Weekly sync",
    "start_time": "2024-12-09T10:00:00Z",
    "end_time": "2024-12-09T11:00:00Z",
    "location": "Conference Room A",
    "all_day": false
  }
}
```

#### Get Schedule
```
GET /api/v1/schedules/:id
Authorization: Bearer <token>
```

#### Update Schedule
```
PATCH /api/v1/schedules/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "schedule": {
    "title": "Updated Meeting Title"
  }
}
```

#### Delete Schedule
```
DELETE /api/v1/schedules/:id
Authorization: Bearer <token>
```

## n8n Integration

This API is designed to work seamlessly with n8n workflows:

1. **Create a user** using the signup endpoint
2. **Get your JWT token** from the login response
3. **Configure n8n HTTP Request nodes** with:
   - Method: POST/GET/PATCH/DELETE
   - URL: `http://your-server:3000/api/v1/calendars` (or other endpoints)
   - Authentication: Generic Credential Type
   - Add Header: `Authorization: Bearer YOUR_TOKEN`

### Example n8n Workflow

1. **Login Node**: HTTP Request to `/api/v1/login` to get token
2. **Create Calendar Node**: HTTP Request to `/api/v1/calendars` with Bearer token
3. **Create Schedule Node**: HTTP Request to `/api/v1/calendars/:id/schedules` with Bearer token

## Database Schema

### Users
- id (primary key)
- name
- email (unique)
- password_digest
- timestamps

### Calendars
- id (primary key)
- name
- description
- timezone
- color
- user_id (foreign key)
- timestamps

### Schedules
- id (primary key)
- title
- description
- start_time
- end_time
- location
- all_day (boolean)
- calendar_id (foreign key)
- timestamps

## Testing

Run the test suite:
```bash
bundle exec rspec
```

## Development

### Running in Development
```bash
rails server
```

### Database Operations
```bash
rails db:migrate        # Run migrations
rails db:rollback      # Rollback last migration
rails db:reset         # Drop, create, and migrate
rails db:seed          # Load seed data
```

## Production Deployment

For production, consider:
1. Using PostgreSQL instead of SQLite
2. Setting environment variables for sensitive data
3. Enabling SSL/HTTPS
4. Setting up proper CORS policies (restrict origins in `config/initializers/cors.rb`)
5. Using a secret key base from environment variables

## License

This project is available as open source.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request