require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  describe 'POST /api/v1/signup' do
    let(:valid_params) do
      {
        user: {
          name: 'John Doe',
          email: 'john@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/api/v1/signup', params: valid_params, as: :json
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['user']['email']).to eq('john@example.com')
        expect(json['token']).to be_present
      end
    end

    context 'with invalid parameters' do
      it 'returns errors' do
        post '/api/v1/signup', params: { user: { email: 'invalid' } }, as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end
  end

  describe 'POST /api/v1/login' do
    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid credentials' do
      it 'returns a token' do
        post '/api/v1/login', params: { email: 'test@example.com', password: 'password123' }, as: :json
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['user']['email']).to eq('test@example.com')
        expect(json['token']).to be_present
      end
    end

    context 'with invalid credentials' do
      it 'returns error' do
        post '/api/v1/login', params: { email: 'test@example.com', password: 'wrong' }, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Invalid email or password')
      end
    end
  end
end
