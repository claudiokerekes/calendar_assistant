# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create sample users
puts "Creating sample users..."

user1 = User.create!(
  name: "John Doe",
  email: "john@example.com",
  password: "password123",
  password_confirmation: "password123"
)

user2 = User.create!(
  name: "Jane Smith",
  email: "jane@example.com",
  password: "password123",
  password_confirmation: "password123"
)

puts "Created #{User.count} users"

# Create sample calendars
puts "Creating sample calendars..."

work_calendar = user1.calendars.create!(
  name: "Work Calendar",
  description: "My work schedule and meetings",
  timezone: "America/New_York",
  color: "#FF5733"
)

personal_calendar = user1.calendars.create!(
  name: "Personal Calendar",
  description: "Personal events and appointments",
  timezone: "America/New_York",
  color: "#3498DB"
)

jane_calendar = user2.calendars.create!(
  name: "Project Calendar",
  description: "Project deadlines and milestones",
  timezone: "Europe/London",
  color: "#2ECC71"
)

puts "Created #{Calendar.count} calendars"

# Create sample schedules
puts "Creating sample schedules..."

# Work schedules for John
work_calendar.schedules.create!(
  title: "Team Standup",
  description: "Daily team sync meeting",
  start_time: 1.day.from_now.change(hour: 9, min: 0),
  end_time: 1.day.from_now.change(hour: 9, min: 30),
  location: "Conference Room A",
  all_day: false
)

work_calendar.schedules.create!(
  title: "Client Presentation",
  description: "Q4 progress presentation for ABC Corp",
  start_time: 2.days.from_now.change(hour: 14, min: 0),
  end_time: 2.days.from_now.change(hour: 15, min: 30),
  location: "Virtual - Zoom",
  all_day: false
)

work_calendar.schedules.create!(
  title: "Sprint Planning",
  description: "Plan next sprint tasks and priorities",
  start_time: 3.days.from_now.change(hour: 10, min: 0),
  end_time: 3.days.from_now.change(hour: 12, min: 0),
  location: "Conference Room B",
  all_day: false
)

# Personal schedules for John
personal_calendar.schedules.create!(
  title: "Dentist Appointment",
  description: "Regular checkup",
  start_time: 4.days.from_now.change(hour: 15, min: 0),
  end_time: 4.days.from_now.change(hour: 16, min: 0),
  location: "Dr. Smith's Office",
  all_day: false
)

personal_calendar.schedules.create!(
  title: "Vacation",
  description: "Summer vacation",
  start_time: 30.days.from_now.beginning_of_day,
  end_time: 37.days.from_now.end_of_day,
  location: "Hawaii",
  all_day: true
)

# Project schedules for Jane
jane_calendar.schedules.create!(
  title: "Project Kickoff",
  description: "New project initialization meeting",
  start_time: 1.day.from_now.change(hour: 11, min: 0),
  end_time: 1.day.from_now.change(hour: 12, min: 30),
  location: "Virtual - Teams",
  all_day: false
)

jane_calendar.schedules.create!(
  title: "Milestone 1 Deadline",
  description: "First project milestone completion",
  start_time: 14.days.from_now.beginning_of_day,
  end_time: 14.days.from_now.end_of_day,
  location: "Remote",
  all_day: true
)

puts "Created #{Schedule.count} schedules"

puts "\n✓ Seed data created successfully!"
puts "\nSample user credentials:"
puts "Email: john@example.com | Password: password123"
puts "Email: jane@example.com | Password: password123"
puts "\nYou can now login and explore the API!"
