class UserBlueprint < Blueprinter::Base
  identifier :id
  fields :email, :coins, :created_at
end
