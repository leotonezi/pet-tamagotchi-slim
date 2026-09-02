class PetDecayJob < ApplicationJob
  queue_as :default

  def perform
    Pet.where(is_alive: true).find_each do |pet|
      PetMechanics.apply_time_decay(pet)
      PetMechanics.refresh_needs_and_health(pet)
      pet.save! if pet.changed?
    end
  end
end
