require 'rails_helper'

RSpec.describe PetMechanics do
  let(:user) { create(:user) }
  let(:pet)  { create(:pet, user: user, last_interaction: Time.current) }

  describe ".feed" do
    it "reduces hunger by 25" do
      pet.update!(hunger: 50)
      PetMechanics.feed(pet)
      expect(pet.reload.hunger).to eq(25)
    end

    it "increases happiness by 5" do
      pet.update!(happiness: 60)
      PetMechanics.feed(pet)
      expect(pet.reload.happiness).to eq(65)
    end

    it "clamps hunger at 0" do
      pet.update!(hunger: 10)
      PetMechanics.feed(pet)
      expect(pet.reload.hunger).to eq(0)
    end

    it "returns failure for dead pet" do
      pet.update!(is_alive: false)
      result = PetMechanics.feed(pet)
      expect(result.success?).to be false
    end
  end

  describe ".walk" do
    it "applies correct deltas" do
      pet.update!(hunger: 50, tiredness: 30, hygiene: 60, happiness: 50)
      PetMechanics.walk(pet)
      pet.reload
      expect(pet.hunger).to eq(55)
      expect(pet.tiredness).to eq(40)
      expect(pet.hygiene).to eq(55)
      expect(pet.happiness).to eq(65)
    end
  end

  describe ".bathe" do
    it "increases hygiene by 50" do
      pet.update!(hygiene: 30)
      PetMechanics.bathe(pet)
      expect(pet.reload.hygiene).to eq(80)
    end

    it "clamps hygiene at 100" do
      pet.update!(hygiene: 70)
      PetMechanics.bathe(pet)
      expect(pet.reload.hygiene).to eq(100)
    end
  end

  describe ".sleep" do
    it "reduces tiredness by 50" do
      pet.update!(tiredness: 60)
      PetMechanics.sleep(pet)
      expect(pet.reload.tiredness).to eq(10)
    end

    it "clamps tiredness at 0" do
      pet.update!(tiredness: 20)
      PetMechanics.sleep(pet)
      expect(pet.reload.tiredness).to eq(0)
    end
  end

  describe ".play" do
    it "increases happiness by 20" do
      pet.update!(happiness: 50)
      PetMechanics.play(pet)
      expect(pet.reload.happiness).to eq(70)
    end

    it "clamps happiness at 100" do
      pet.update!(happiness: 90)
      PetMechanics.play(pet)
      expect(pet.reload.happiness).to eq(100)
    end
  end

  describe ".refresh_needs_and_health" do
    it "sets needs_meal when hunger > 70" do
      pet.hunger = 71
      PetMechanics.refresh_needs_and_health(pet)
      expect(pet.needs_meal).to be true
    end

    it "sets needs_walk when happiness < 60" do
      pet.happiness = 59
      PetMechanics.refresh_needs_and_health(pet)
      expect(pet.needs_walk).to be true
    end

    it "sets needs_bath when hygiene < 40" do
      pet.hygiene = 39
      PetMechanics.refresh_needs_and_health(pet)
      expect(pet.needs_bath).to be true
    end

    it "calculates health correctly" do
      pet.hunger = 30; pet.tiredness = 20; pet.hygiene = 80; pet.happiness = 70
      PetMechanics.refresh_needs_and_health(pet)
      expected = ((100 - 30) + (100 - 20) + 80 + 70) / 4
      expect(pet.health).to eq(expected)
    end

    it "kills pet when hunger > 95" do
      pet.hunger = 96
      PetMechanics.refresh_needs_and_health(pet)
      expect(pet.is_alive).to be false
    end

    it "kills pet when hygiene < 10" do
      pet.hygiene = 9
      PetMechanics.refresh_needs_and_health(pet)
      expect(pet.is_alive).to be false
    end

    it "kills pet when happiness < 5" do
      pet.happiness = 4
      PetMechanics.refresh_needs_and_health(pet)
      expect(pet.is_alive).to be false
    end
  end

  describe ".apply_time_decay" do
    it "increases hunger based on elapsed hours" do
      pet.update!(hunger: 10, last_interaction: 8.hours.ago)
      PetMechanics.apply_time_decay(pet)
      expect(pet.hunger).to eq(12) # 8h / 4 = 2 increase
    end

    it "decreases hygiene based on elapsed hours" do
      pet.update!(hygiene: 80, last_interaction: 12.hours.ago)
      PetMechanics.apply_time_decay(pet)
      expect(pet.hygiene).to eq(78) # 12h / 6 = 2 decrease
    end

    it "decreases tiredness based on elapsed hours" do
      pet.update!(tiredness: 40, last_interaction: 8.hours.ago)
      PetMechanics.apply_time_decay(pet)
      expect(pet.tiredness).to eq(38) # 8h / 4 = 2 decrease
    end

    it "clamps stats at boundaries" do
      pet.update!(hunger: 99, hygiene: 1, last_interaction: 48.hours.ago)
      PetMechanics.apply_time_decay(pet)
      expect(pet.hunger).to eq(100)
      expect(pet.hygiene).to eq(0)
    end
  end
end
