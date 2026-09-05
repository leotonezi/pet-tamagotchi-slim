require 'rails_helper'

RSpec.describe "Rewards", type: :request do
  let(:user)    { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/rewards" do
    it "returns eligible true when no prior claim" do
      get "/api/v1/rewards", headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["eligible"]).to be true
      expect(body["last_claimed_at"]).to be_nil
    end

    it "returns eligible false within cooldown" do
      user.create_claim_state!(last_claimed_at: 1.hour.ago)
      get "/api/v1/rewards", headers: headers
      body = JSON.parse(response.body)
      expect(body["eligible"]).to be false
      expect(body["next_claim_at"]).to be_present
    end

    it "returns eligible true after cooldown" do
      user.create_claim_state!(last_claimed_at: 25.hours.ago)
      get "/api/v1/rewards", headers: headers
      expect(JSON.parse(response.body)["eligible"]).to be true
    end

    it "requires auth" do
      get "/api/v1/rewards"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/rewards/claim" do
    it "awards coins and records claim time" do
      expect {
        post "/api/v1/rewards/claim", headers: headers
      }.to change { user.reload.coins }.by_at_least(10)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["coins_awarded"]).to be_between(10, 25)
      expect(body["total_coins"]).to eq(user.coins)
    end

    it "creates claim_state on first claim" do
      post "/api/v1/rewards/claim", headers: headers
      expect(user.reload.claim_state.last_claimed_at).to be_within(5.seconds).of(Time.current)
    end

    it "rejects double-claim within cooldown" do
      user.create_claim_state!(last_claimed_at: 1.hour.ago)
      post "/api/v1/rewards/claim", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to match(/next reward/i)
    end

    it "allows claim again after cooldown" do
      user.create_claim_state!(last_claimed_at: 25.hours.ago)
      post "/api/v1/rewards/claim", headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "requires auth" do
      post "/api/v1/rewards/claim"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
