class InventorySlotBlueprint < Blueprinter::Base
  identifier :id
  field :qty
  association :item, blueprint: ItemBlueprint
end

class InventoryBlueprint < Blueprinter::Base
  identifier :id
  association :inventory_slots, blueprint: InventorySlotBlueprint
end
