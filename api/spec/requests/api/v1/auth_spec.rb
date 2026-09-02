require 'rails_helper'

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/sign_up" do
    let(:params) { { user: { email: "new@example.com", password: "password123" } } }

    it "creates user and returns token" do
      post "/api/v1/auth/sign_up", params: params.to_json, headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body["user"]["email"]).to eq("new@example.com")
      expect(body["user"]["coins"]).to eq(0)
    end

    it "returns 422 for duplicate email" do
      create(:user, email: "new@example.com")
      post "/api/v1/auth/sign_up", params: params.to_json, headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to be_present
    end

    it "returns 422 for missing password" do
      post "/api/v1/auth/sign_up",
        params: { user: { email: "new@example.com" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/auth/sign_in" do
    let!(:user) { create(:user, email: "login@example.com", password: "password123") }

    it "returns token on valid credentials" do
      post "/api/v1/auth/sign_in",
        params: { user: { email: "login@example.com", password: "password123" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body["user"]["email"]).to eq("login@example.com")
    end

    it "returns 401 on wrong password" do
      post "/api/v1/auth/sign_in",
        params: { user: { email: "login@example.com", password: "wrong" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to be_present
    end

    it "returns 401 on unknown email" do
      post "/api/v1/auth/sign_in",
        params: { user: { email: "nobody@example.com", password: "password123" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/me" do
    let!(:user) { create(:user) }

    it "returns current user" do
      get "/api/v1/auth/me", headers: auth_headers_for(user)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["email"]).to eq(user.email)
    end

    it "returns 401 without token" do
      get "/api/v1/auth/me"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/sign_out" do
    let!(:user) { create(:user) }

    it "revokes token" do
      headers = auth_headers_for(user)
      delete "/api/v1/auth/sign_out", headers: headers
      expect(response).to have_http_status(:ok)
      get "/api/v1/auth/me", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
