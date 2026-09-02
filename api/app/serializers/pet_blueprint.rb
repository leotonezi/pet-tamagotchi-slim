class PetBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :species, :hunger, :tiredness, :hygiene, :happiness,
         :health, :needs_meal, :needs_walk, :needs_bath, :is_alive,
         :birth_date, :last_interaction
end
