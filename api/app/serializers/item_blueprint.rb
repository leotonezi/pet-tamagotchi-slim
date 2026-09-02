class ItemBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :description, :price_coins,
         :hunger_delta, :hygiene_delta, :happiness_delta, :tiredness_delta
end
