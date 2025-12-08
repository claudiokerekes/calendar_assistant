require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:calendars).dependent(:destroy) }
    it { should have_many(:schedules).through(:calendars) }
  end

  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:email) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
  end

  describe '#generate_token' do
    let(:user) { create(:user) }
    
    it 'generates a JWT token' do
      token = user.generate_token
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end
    
    it 'token contains user_id' do
      token = user.generate_token
      decoded = JWT.decode(token, Rails.application.secret_key_base).first
      expect(decoded['user_id']).to eq(user.id)
    end
  end

  describe 'email normalization' do
    it 'downcases email before save' do
      user = create(:user, email: 'USER@EXAMPLE.COM')
      expect(user.email).to eq('user@example.com')
    end
  end
end
