class CreateInventorySlots < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_slots do |t|
      t.references :inventory, null: false, foreign_key: true
      t.references :item,      null: false, foreign_key: true
      t.integer :qty,          null: false, default: 0
      t.timestamps
    end

    add_index :inventory_slots, [ :inventory_id, :item_id ], unique: true
  end
end
