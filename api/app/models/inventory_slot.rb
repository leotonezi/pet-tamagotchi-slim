class InventorySlot < ApplicationRecord
  belongs_to :inventory
  belongs_to :item

  validates :qty, numericality: { greater_than_or_equal_to: 0 }
end
