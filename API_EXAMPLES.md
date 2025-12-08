# API Usage Examples

This document provides practical examples of using the Calendar Assistant API with curl and n8n.

## Prerequisites

- Server running at `http://localhost:3000` (or your production URL)
- A REST client (curl, Postman, or n8n)

## Example Workflow

### 1. Create a User Account

```bash
curl -X POST http://localhost:3000/api/v1/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "John Doe",
      "email": "john@example.com",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
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

Save the token for subsequent requests!

### 2. Login (if you already have an account)

```bash
curl -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

### 3. Create a Calendar

```bash
TOKEN="your_token_here"
curl -X POST http://localhost:3000/api/v1/calendars \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "calendar": {
      "name": "Work Calendar",
      "description": "My work schedule",
      "timezone": "America/New_York",
      "color": "#FF5733"
    }
  }'
```

### 4. List All Calendars

```bash
curl -X GET http://localhost:3000/api/v1/calendars \
  -H "Authorization: Bearer $TOKEN"
```

### 5. Create a Schedule

```bash
curl -X POST http://localhost:3000/api/v1/calendars/1/schedules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "schedule": {
      "title": "Team Meeting",
      "description": "Weekly sync with the team",
      "start_time": "2024-12-09T10:00:00Z",
      "end_time": "2024-12-09T11:00:00Z",
      "location": "Conference Room A",
      "all_day": false
    }
  }'
```

### 6. List All Schedules

```bash
# Get all schedules for the user
curl -X GET http://localhost:3000/api/v1/schedules \
  -H "Authorization: Bearer $TOKEN"

# Get schedules for a specific calendar
curl -X GET http://localhost:3000/api/v1/calendars/1/schedules \
  -H "Authorization: Bearer $TOKEN"

# Filter upcoming schedules only
curl -X GET "http://localhost:3000/api/v1/schedules?upcoming=true" \
  -H "Authorization: Bearer $TOKEN"
```

### 7. Update a Schedule

```bash
curl -X PATCH http://localhost:3000/api/v1/schedules/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "schedule": {
      "title": "Updated Meeting Title",
      "location": "Virtual - Zoom"
    }
  }'
```

### 8. Delete a Schedule

```bash
curl -X DELETE http://localhost:3000/api/v1/schedules/1 \
  -H "Authorization: Bearer $TOKEN"
```

## n8n Integration Guide

### Setting Up n8n Workflow

#### 1. Login Node (HTTP Request)

- **Method**: POST
- **URL**: `http://your-server:3000/api/v1/login`
- **Body Parameters**:
  ```json
  {
    "email": "john@example.com",
    "password": "password123"
  }
  ```
- **Output**: Save `{{ $json.token }}` to use in subsequent nodes

#### 2. Create Calendar Node (HTTP Request)

- **Method**: POST
- **URL**: `http://your-server:3000/api/v1/calendars`
- **Authentication**: None (we'll use custom headers)
- **Headers**:
  - Name: `Authorization`
  - Value: `Bearer {{ $node["Login"].json.token }}`
  - Name: `Content-Type`
  - Value: `application/json`
- **Body Parameters**:
  ```json
  {
    "calendar": {
      "name": "Automated Calendar",
      "description": "Created by n8n",
      "timezone": "UTC"
    }
  }
  ```

#### 3. Create Schedule Node (HTTP Request)

- **Method**: POST
- **URL**: `http://your-server:3000/api/v1/calendars/{{ $json.calendar.id }}/schedules`
- **Headers**:
  - Name: `Authorization`
  - Value: `Bearer {{ $node["Login"].json.token }}`
  - Name: `Content-Type`
  - Value: `application/json`
- **Body Parameters**:
  ```json
  {
    "schedule": {
      "title": "Automated Event",
      "description": "Created by n8n workflow",
      "start_time": "{{ $now }}",
      "end_time": "{{ $now.plus({ hours: 1 }) }}",
      "all_day": false
    }
  }
  ```

#### 4. List Schedules Node (HTTP Request)

- **Method**: GET
- **URL**: `http://your-server:3000/api/v1/schedules?upcoming=true`
- **Headers**:
  - Name: `Authorization`
  - Value: `Bearer {{ $node["Login"].json.token }}`

### Example n8n Workflow: Daily Schedule Summary

1. **Schedule Trigger**: Cron expression `0 8 * * *` (every day at 8 AM)
2. **Login Node**: Get authentication token
3. **List Schedules**: Get today's schedules with `?date={{ $now.toFormat('yyyy-MM-dd') }}`
4. **Process Data**: Use Function node to format schedules
5. **Send Email/Notification**: Use Email or Slack node to send summary

### Example n8n Workflow: Create Event from Form

1. **Webhook Trigger**: Receive form data
2. **Login Node**: Authenticate
3. **Create Calendar** (if needed): Set up new calendar
4. **Create Schedule**: Add event from webhook data
5. **Response**: Send confirmation back to webhook

## Error Handling

### Common Error Responses

#### 401 Unauthorized
```json
{
  "errors": ["Unauthorized"]
}
```
**Solution**: Check your token is valid and included in the Authorization header

#### 404 Not Found
```json
{
  "errors": ["Calendar not found"]
}
```
**Solution**: Verify the resource ID exists and belongs to the authenticated user

#### 422 Unprocessable Entity
```json
{
  "errors": ["End time must be after start time"]
}
```
**Solution**: Check your input data meets validation requirements

## Best Practices

1. **Token Management**: Store tokens securely and refresh when expired (24 hours)
2. **Error Handling**: Always check response status codes and handle errors gracefully
3. **Rate Limiting**: Consider implementing rate limiting in production
4. **Timezone Handling**: Use consistent timezone formats (ISO 8601)
5. **Pagination**: For large datasets, implement pagination (to be added in future version)

## Testing with Different Tools

### Postman

1. Create a new collection
2. Add environment variables for `base_url` and `token`
3. Use `{{base_url}}` and `{{token}}` in requests
4. Set up authentication in collection settings

### HTTPie

```bash
# Signup
http POST localhost:3000/api/v1/signup user:='{"name":"Test","email":"test@example.com","password":"pass123","password_confirmation":"pass123"}'

# Login
http POST localhost:3000/api/v1/login email=test@example.com password=pass123

# Create calendar (with token)
http POST localhost:3000/api/v1/calendars Authorization:"Bearer YOUR_TOKEN" calendar:='{"name":"Test Calendar","timezone":"UTC"}'
```

## Production Considerations

When deploying to production:

1. **Use HTTPS**: Always use SSL/TLS in production
2. **Environment Variables**: Store sensitive data in environment variables
3. **CORS Configuration**: Restrict CORS origins in `config/initializers/cors.rb`
4. **Database**: Switch to PostgreSQL for production (see README for config)
5. **Secret Key**: Use a strong secret key base (generate with `rails secret`)
6. **Monitoring**: Set up logging and monitoring for API usage
7. **Backup**: Regular database backups

## Support

For issues or questions:
- Check the main README.md for documentation
- Review the test files in `spec/` for more examples
- Open an issue on GitHub
