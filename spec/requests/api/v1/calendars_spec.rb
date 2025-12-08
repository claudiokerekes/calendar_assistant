require 'rails_helper'

RSpec.describe 'Api::V1::Calendars', type: :request do
  let(:user) { create(:user) }
  let(:token) { user.generate_token }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/calendars' do
    let!(:calendars) { create_list(:calendar, 3, user: user) }

    it 'returns all calendars for the user' do
      get '/api/v1/calendars', headers: headers, as: :json
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['calendars'].length).to eq(3)
    end

    it 'requires authentication' do
      get '/api/v1/calendars', as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/calendars' do
    let(:valid_params) do
      {
        calendar: {
          name: 'Work Calendar',
          description: 'My work schedule',
          timezone: 'America/New_York'
        }
      }
    end

    it 'creates a new calendar' do
      expect {
        post '/api/v1/calendars', params: valid_params, headers: headers, as: :json
      }.to change(Calendar, :count).by(1)
      
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['calendar']['name']).to eq('Work Calendar')
    end
  end

  describe 'GET /api/v1/calendars/:id' do
    let(:calendar) { create(:calendar, user: user) }

    it 'returns the calendar' do
      get "/api/v1/calendars/#{calendar.id}", headers: headers, as: :json
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['calendar']['id']).to eq(calendar.id)
    end
  end

  describe 'PATCH /api/v1/calendars/:id' do
    let(:calendar) { create(:calendar, user: user) }

    it 'updates the calendar' do
      patch "/api/v1/calendars/#{calendar.id}", 
        params: { calendar: { name: 'Updated Name' } },
        headers: headers,
        as: :json
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['calendar']['name']).to eq('Updated Name')
    end
  end

  describe 'DELETE /api/v1/calendars/:id' do
    let!(:calendar) { create(:calendar, user: user) }

    it 'deletes the calendar' do
      expect {
        delete "/api/v1/calendars/#{calendar.id}", headers: headers, as: :json
      }.to change(Calendar, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
    end
  end
end
