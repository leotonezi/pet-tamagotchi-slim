class Inventory < ApplicationRecord
  belongs_to :user
  has_many :inventory_slots, dependent: :destroy
  has_many :items, through: :inventory_slots
end
