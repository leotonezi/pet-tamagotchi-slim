module BreedService
  Result = Struct.new(:success?, :error, :offspring, keyword_init: true)

  INHERITED_STATS = %i[hunger tiredness hygiene happiness].freeze

  def self.breed(user:, parent_a_id:, parent_b_id:, offspring_name:)
    parent_a = user.pets.find_by(id: parent_a_id)
    parent_b = user.pets.find_by(id: parent_b_id)

    return Result.new(success?: false, error: "Parent not found") unless parent_a && parent_b
    return Result.new(success?: false, error: "Parents must be different pets") if parent_a.id == parent_b.id
    return Result.new(success?: false, error: "#{parent_a.name} is not alive") unless parent_a.is_alive
    return Result.new(success?: false, error: "#{parent_b.name} is not alive") unless parent_b.is_alive

    offspring = nil

    ActiveRecord::Base.transaction do
      stats = INHERITED_STATS.index_with do |stat|
        SecureRandom.random_number(2) == 0 ? parent_a.send(stat) : parent_b.send(stat)
      end

      offspring = user.pets.create!(
        name: offspring_name,
        species: blend_species(parent_a.species, parent_b.species),
        **stats
      )

      PetMechanics.refresh_needs_and_health(offspring)
      offspring.save!

      BreedRecord.create!(
        owner: user,
        parent_a: parent_a,
        parent_b: parent_b,
        offspring: offspring
      )
    end

    Result.new(success?: true, offspring: offspring)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success?: false, error: e.record.errors.full_messages.first)
  rescue => e
    Result.new(success?: false, error: e.message)
  end

  private_class_method def self.blend_species(a, b)
    half_a = a[0, (a.length.to_f / 2).ceil]
    half_b = b[(b.length / 2)..]
    "#{half_a}#{half_b}"[0, 16]
  end
end
