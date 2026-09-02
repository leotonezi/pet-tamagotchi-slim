require 'rails_helper'

RSpec.describe "Api::V1::Pets", type: :request do
  let!(:user)  { create(:user) }
  let!(:other) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/pets" do
    it "returns user's pets" do
      create_list(:pet, 2, user: user)
      create(:pet, user: other)
      get "/api/v1/pets", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(2)
    end

    it "returns 401 without token" do
      get "/api/v1/pets"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/pets" do
    let(:params) { { pet: { name: "Fluffy", species: "Cat" } }.to_json }
    let(:json_header) { headers.merge("Content-Type" => "application/json") }

    it "creates pet" do
      post "/api/v1/pets", params: params, headers: json_header
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("Fluffy")
      expect(body["is_alive"]).to be true
    end

    it "returns 422 on duplicate name for same user" do
      create(:pet, user: user, name: "Fluffy")
      post "/api/v1/pets", params: params, headers: json_header
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/pets/:id" do
    let!(:pet) { create(:pet, user: user) }

    it "returns pet and applies decay" do
      get "/api/v1/pets/#{pet.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(pet.id)
    end

    it "returns 404 for another user's pet" do
      other_pet = create(:pet, user: other)
      get "/api/v1/pets/#{other_pet.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/pets/:id" do
    let!(:pet) { create(:pet, user: user) }

    it "deletes pet" do
      delete "/api/v1/pets/#{pet.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(Pet.exists?(pet.id)).to be false
    end

    it "cannot delete another user's pet" do
      other_pet = create(:pet, user: other)
      delete "/api/v1/pets/#{other_pet.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "care actions" do
    let!(:pet) { create(:pet, user: user, hunger: 50, happiness: 70) }

    %w[feed walk bathe sleep play].each do |action|
      it "POST #{action} returns updated pet" do
        post "/api/v1/pets/#{pet.id}/#{action}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["id"]).to eq(pet.id)
      end
    end

    it "cannot perform care on dead pet" do
      pet.update!(is_alive: false)
      post "/api/v1/pets/#{pet.id}/feed", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "cannot perform care on another user's pet" do
      other_pet = create(:pet, user: other)
      post "/api/v1/pets/#{other_pet.id}/feed", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
