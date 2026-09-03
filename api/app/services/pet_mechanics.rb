module PetMechanics
  Result = Struct.new(:success?, :error, keyword_init: true)

  FEED_DURATION  = 15.minutes
  WALK_DURATION  = 30.minutes
  BATHE_DURATION = 10.minutes

  def self.feed(pet)
    care_action(pet, action: "feeding", duration: FEED_DURATION) do
      pet.hunger    = clamp(pet.hunger - 25)
      pet.happiness = clamp(pet.happiness + 5)
    end
  end

  def self.walk(pet)
    care_action(pet, action: "walking", duration: WALK_DURATION) do
      pet.hunger    = clamp(pet.hunger + 5)
      pet.tiredness = clamp(pet.tiredness + 10)
      pet.hygiene   = clamp(pet.hygiene - 5)
      pet.happiness = clamp(pet.happiness + 15)
    end
  end

  def self.bathe(pet)
    care_action(pet, action: "bathing", duration: BATHE_DURATION) do
      pet.hygiene   = clamp(pet.hygiene + 50)
      pet.happiness = clamp(pet.happiness + 5)
    end
  end

  def self.sleep(pet, hours:)
    valid = [ 4, 8 ]
    unless valid.include?(hours)
      return Result.new(success?: false, error: "Sleep duration must be 4 or 8 hours")
    end

    scale = hours / 8.0
    care_action(pet, action: "sleeping", duration: hours.hours) do
      pet.hunger    = clamp(pet.hunger    + (5  * scale).round)
      pet.tiredness = clamp(pet.tiredness - (50 * scale).round)
    end
  end

  def self.play(pet, hours:)
    valid = [ 1, 2, 4 ]
    unless valid.include?(hours)
      return Result.new(success?: false, error: "Play duration must be 1, 2, or 4 hours")
    end

    scale = hours / 4.0
    care_action(pet, action: "playing", duration: hours.hours) do
      pet.hunger    = clamp(pet.hunger    + (5  * scale).round)
      pet.tiredness = clamp(pet.tiredness + (10 * scale).round)
      pet.happiness = clamp(pet.happiness + (20 * scale).round)
    end
  end

  def self.use_item(pet, item)
    unless pet.is_alive
      return Result.new(success?: false, error: "Pet is not alive")
    end

    pet.with_lock do
      apply_time_decay(pet)
      pet.hunger    = clamp(pet.hunger    + item.hunger_delta)
      pet.hygiene   = clamp(pet.hygiene   + item.hygiene_delta)
      pet.happiness = clamp(pet.happiness + item.happiness_delta)
      pet.tiredness = clamp(pet.tiredness + item.tiredness_delta)
      refresh_needs_and_health(pet)
      pet.save!
    end
    Result.new(success?: true)
  rescue => e
    Result.new(success?: false, error: e.message)
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
    now = Time.current

    # clear finished action
    if pet.action_ends_at.present? && now >= pet.action_ends_at
      pet.active_action  = nil
      pet.action_ends_at = nil
    end

    elapsed_minutes = (now - pet.last_interaction) / 60.0
    pet.hunger    = clamp(pet.hunger    + (elapsed_minutes / 5.0).floor)
    pet.tiredness = clamp(pet.tiredness - (elapsed_minutes / 5.0).floor)
    pet.hygiene   = clamp(pet.hygiene   - (elapsed_minutes / 10.0).floor)
    pet.last_interaction = now
  end

  def self.refresh_needs_and_health(pet)
    pet.needs_meal = pet.hunger    > 70
    pet.needs_walk = pet.happiness < 60
    pet.needs_bath = pet.hygiene   < 40
    pet.health     = ((100 - pet.hunger) + (100 - pet.tiredness) + pet.hygiene + pet.happiness) / 4
    pet.is_alive   = false if pet.hunger > 95 || pet.hygiene < 10 || pet.happiness < 5
  end

  private_class_method def self.care_action(pet, action:, duration:)
    unless pet.is_alive
      return Result.new(success?: false, error: "Pet is not alive")
    end

    result = Result.new(success?: true)

    pet.with_lock do
      apply_time_decay(pet)

      if busy?(pet)
        result = Result.new(success?: false, error: "Pet is busy #{pet.active_action}")
        next
      end

      yield
      pet.active_action  = action
      pet.action_ends_at = Time.current + duration
      refresh_needs_and_health(pet)
      pet.save!
    end

    result
  rescue => e
    Result.new(success?: false, error: e.message)
  end

  private_class_method def self.busy?(pet)
    pet.active_action.present? && pet.action_ends_at.present? && Time.current < pet.action_ends_at
  end

  private_class_method def self.clamp(val)
    val.clamp(0, 100)
  end
end
