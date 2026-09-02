require 'rails_helper'

RSpec.describe "Api::V1::Inventory", type: :request do
  let!(:user)  { create(:user, coins: 50) }
  let!(:item)  { Item.find_by(name: "Apple") || create(:item, name: "Apple", price_coins: 10, hunger_delta: -30) }
  let(:headers) { auth_headers_for(user) }
  let(:json)    { { "Content-Type" => "application/json" } }

  describe "GET /api/v1/inventory" do
    it "returns inventory with slots" do
      get "/api/v1/inventory", headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to have_key("inventory_slots")
    end
  end

  describe "POST /api/v1/inventory/buy" do
    it "buys item and deducts coins" do
      post "/api/v1/inventory/buy",
        params: { item_id: item.id, qty: 2 }.to_json,
        headers: headers.merge(json)
      expect(response).to have_http_status(:ok)
      expect(user.reload.coins).to eq(30)
      slot = user.inventory.inventory_slots.find_by(item: item)
      expect(slot.qty).to eq(2)
    end

    it "returns 422 when not enough coins" do
      user.update!(coins: 5)
      post "/api/v1/inventory/buy",
        params: { item_id: item.id, qty: 1 }.to_json,
        headers: headers.merge(json)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.coins).to eq(5)
    end
  end

  describe "POST /api/v1/inventory/use" do
    let!(:pet) { create(:pet, user: user) }

    before do
      user.inventory.inventory_slots.create!(item: item, qty: 2)
    end

    it "uses item and updates pet stats" do
      original_hunger = pet.hunger
      post "/api/v1/inventory/use",
        params: { item_id: item.id, pet_id: pet.id }.to_json,
        headers: headers.merge(json)
      expect(response).to have_http_status(:ok)
      expect(pet.reload.hunger).to be < original_hunger
      slot = user.inventory.inventory_slots.find_by(item: item)
      expect(slot.qty).to eq(1)
    end

    it "returns 422 when item not in inventory" do
      other_item = create(:item, name: "Soap", price_coins: 10)
      post "/api/v1/inventory/use",
        params: { item_id: other_item.id, pet_id: pet.id }.to_json,
        headers: headers.merge(json)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 when using item on dead pet" do
      pet.update!(is_alive: false)
      post "/api/v1/inventory/use",
        params: { item_id: item.id, pet_id: pet.id }.to_json,
        headers: headers.merge(json)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for another user's pet" do
      other_pet = create(:pet, user: create(:user))
      post "/api/v1/inventory/use",
        params: { item_id: item.id, pet_id: other_pet.id }.to_json,
        headers: headers.merge(json)
      expect(response).to have_http_status(:not_found)
    end
  end
end
