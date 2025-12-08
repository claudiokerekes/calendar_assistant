require 'rails_helper'

RSpec.describe Schedule, type: :model do
  describe 'associations' do
    it { should belong_to(:calendar) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }
    
    context 'end_time validation' do
      let(:calendar) { create(:calendar) }
      
      it 'is invalid when end_time is before start_time' do
        schedule = build(:schedule, 
          calendar: calendar,
          start_time: Time.current,
          end_time: 1.hour.ago
        )
        expect(schedule).not_to be_valid
        expect(schedule.errors[:end_time]).to include('must be after start time')
      end
      
      it 'is valid when end_time is after start_time' do
        schedule = build(:schedule,
          calendar: calendar,
          start_time: Time.current,
          end_time: 1.hour.from_now
        )
        expect(schedule).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:calendar) { create(:calendar) }
    
    before do
      create(:schedule, calendar: calendar, start_time: 1.day.ago, end_time: 1.day.ago + 1.hour)
      create(:schedule, calendar: calendar, start_time: 1.day.from_now, end_time: 1.day.from_now + 1.hour)
    end
    
    it 'upcoming scope returns future schedules' do
      expect(Schedule.upcoming.count).to eq(1)
    end
    
    it 'past scope returns past schedules' do
      expect(Schedule.past.count).to eq(1)
    end
  end
end
