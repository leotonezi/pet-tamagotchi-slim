class Item < ApplicationRecord
  has_many :inventory_slots, dependent: :destroy

  validates :name, presence: true
  validates :price_coins, numericality: { greater_than_or_equal_to: 0 }
end
