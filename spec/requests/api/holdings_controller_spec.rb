require 'rails_helper'

RSpec.describe Api::HoldingsController, type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe 'GET /api/holdings' do
    it 'returns the portfolio data for the current user' do
      create(:holding, user: user, label: 'BTC', quantity: 1.5, category: 'crypto')
      create(:price, label: 'BTC', price: 20_000, retrieved_at: 1.hour.ago)
      create(:portfolio_snapshot, user: user, total_value: 10_000, taken_at: 1.day.ago) # factory definita!

      get '/api/holdings', headers: headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['assets']).to be_present
      expect(json['totals']).to be_present
      expect(json['history']).to be_present
    end
  end

  describe 'POST /api/holdings' do
    it 'creates a new holding' do
      create(:price, label: 'ETH', price: 1500, retrieved_at: 1.hour.ago)

      post '/api/holdings', params: {
        holding: {
          label: 'ETH',
          quantity: 2.0,
          category: 'crypto'
        }
      }.to_json, headers: headers

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json['assets']).to be_present
    end
  end

  describe 'PUT /api/holdings/:id' do
    it 'updates an existing holding' do
      holding = create(:holding, user: user, label: 'BTC', quantity: 1.0)
      create(:price, label: 'BTC', price: 20_000, retrieved_at: 1.hour.ago)

      put "/api/holdings/#{holding.label}", params: {
        holding: {
          quantity: 2.0
        }
      }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      holding.reload
      expect(holding.quantity).to eq(2.0)
    end
  end

  describe 'DELETE /api/holdings/:id' do
    it 'deletes the holding' do
      holding = create(:holding, user: user, label: 'BTC', quantity: 1.0)

      delete "/api/holdings/#{holding.label}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(Holding.exists?(holding.id)).to be_falsey
    end
  end
end
