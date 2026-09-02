module PetMechanics
  Result = Struct.new(:success?, :error, keyword_init: true)

  def self.feed(pet)
    care_action(pet) do
      pet.hunger    = clamp(pet.hunger - 25)
      pet.happiness = clamp(pet.happiness + 5)
    end
  end

  def self.walk(pet)
    care_action(pet) do
      pet.hunger    = clamp(pet.hunger + 5)
      pet.tiredness = clamp(pet.tiredness + 10)
      pet.hygiene   = clamp(pet.hygiene - 5)
      pet.happiness = clamp(pet.happiness + 15)
    end
  end

  def self.bathe(pet)
    care_action(pet) do
      pet.hygiene   = clamp(pet.hygiene + 50)
      pet.happiness = clamp(pet.happiness + 5)
    end
  end

  def self.sleep(pet)
    care_action(pet) do
      pet.hunger    = clamp(pet.hunger + 5)
      pet.tiredness = clamp(pet.tiredness - 50)
    end
  end

  def self.play(pet)
    care_action(pet) do
      pet.hunger    = clamp(pet.hunger + 5)
      pet.tiredness = clamp(pet.tiredness + 10)
      pet.happiness = clamp(pet.happiness + 20)
    end
  end

  def self.check_status(pet)
    pet.with_lock do
      apply_time_decay(pet)
      refresh_needs_and_health(pet)
      pet.save!
    end
    Result.new(success?: true)
  rescue => e
    Result.new(success?: false, error: e.message)
  end

  def self.apply_time_decay(pet)
    elapsed_hours = (Time.current - pet.last_interaction) / 3600.0

    pet.hunger    = clamp(pet.hunger    + (elapsed_hours / 4.0).floor)
    pet.tiredness = clamp(pet.tiredness - (elapsed_hours / 4.0).floor)
    pet.hygiene   = clamp(pet.hygiene   - (elapsed_hours / 6.0).floor)

    pet.last_interaction = Time.current
  end

  def self.refresh_needs_and_health(pet)
    pet.needs_meal = pet.hunger   > 70
    pet.needs_walk = pet.happiness < 60
    pet.needs_bath = pet.hygiene   < 40
    pet.health     = ((100 - pet.hunger) + (100 - pet.tiredness) + pet.hygiene + pet.happiness) / 4
    pet.is_alive   = false if pet.hunger > 95 || pet.hygiene < 10 || pet.happiness < 5
  end

  private_class_method def self.care_action(pet)
    unless pet.is_alive
      return Result.new(success?: false, error: "Pet is not alive")
    end

    pet.with_lock do
      apply_time_decay(pet)
      yield
      refresh_needs_and_health(pet)
      pet.save!
    end
    Result.new(success?: true)
  rescue => e
    Result.new(success?: false, error: e.message)
  end

  private_class_method def self.clamp(val)
    val.clamp(0, 100)
  end
end
