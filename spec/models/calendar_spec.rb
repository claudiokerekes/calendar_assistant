require 'rails_helper'

RSpec.describe Calendar, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:schedules).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:timezone) }
  end

  describe 'default values' do
    it 'sets default timezone to UTC' do
      user = create(:user)
      calendar = Calendar.new(name: 'Test Calendar', user: user)
      expect(calendar.timezone).to eq('UTC')
    end
  end
end
