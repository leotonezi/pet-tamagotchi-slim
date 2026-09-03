class BreedRecord < ApplicationRecord
  belongs_to :owner,    class_name: "User"
  belongs_to :parent_a, class_name: "Pet"
  belongs_to :parent_b, class_name: "Pet"
  belongs_to :offspring, class_name: "Pet"
end
