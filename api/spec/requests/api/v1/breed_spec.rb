require 'rails_helper'

RSpec.describe "POST /api/v1/breed", type: :request do
  let(:user)    { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:pet_a)   { create(:pet, user: user, name: "Alpha", species: "Cat") }
  let(:pet_b)   { create(:pet, user: user, name: "Beta",  species: "Dog") }

  def breed(params)
    post "/api/v1/breed", params: params, headers: headers, as: :json
  end

  it "creates offspring with blended species" do
    breed(parent_a_id: pet_a.id, parent_b_id: pet_b.id, name: "Pup")
    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body["name"]).to eq("Pup")
    expect(body["species"]).to eq("Caog")
    expect(body["id"]).not_to eq(pet_a.id)
    expect(body["id"]).not_to eq(pet_b.id)
  end

  it "creates a BreedRecord" do
    expect { breed(parent_a_id: pet_a.id, parent_b_id: pet_b.id, name: "Kid") }
      .to change(BreedRecord, :count).by(1)
  end

  it "rejects same pet as both parents" do
    breed(parent_a_id: pet_a.id, parent_b_id: pet_a.id, name: "Clone")
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"]).to match(/different/)
  end

  it "rejects dead parent" do
    pet_a.update!(is_alive: false)
    breed(parent_a_id: pet_a.id, parent_b_id: pet_b.id, name: "Kid")
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"]).to match(/not alive/)
  end

  it "rejects pet from another user" do
    other_pet = create(:pet, user: create(:user))
    breed(parent_a_id: pet_a.id, parent_b_id: other_pet.id, name: "Kid")
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"]).to match(/not found/i)
  end

  it "requires auth" do
    post "/api/v1/breed", params: { parent_a_id: pet_a.id, parent_b_id: pet_b.id, name: "Kid" }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "requires name param" do
    post "/api/v1/breed", params: { parent_a_id: pet_a.id, parent_b_id: pet_b.id }, headers: headers, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
