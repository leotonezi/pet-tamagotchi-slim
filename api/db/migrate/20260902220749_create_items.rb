class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string  :name,              null: false
      t.text    :description
      t.integer :price_coins,       null: false
      t.integer :hunger_delta,      null: false, default: 0
      t.integer :hygiene_delta,     null: false, default: 0
      t.integer :happiness_delta,   null: false, default: 0
      t.integer :tiredness_delta,   null: false, default: 0
      t.timestamps
    end
  end
end
