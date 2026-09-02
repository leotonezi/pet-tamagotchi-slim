class CreatePets < ActiveRecord::Migration[8.1]
  def change
    create_table :pets do |t|
      t.references :user, null: false, foreign_key: true

      t.string  :name,             null: false, limit: 32
      t.string  :species,          null: false, limit: 16

      t.integer :hunger,           null: false, default: 30
      t.integer :tiredness,        null: false, default: 20
      t.integer :hygiene,          null: false, default: 80
      t.integer :happiness,        null: false, default: 70
      t.integer :health,           null: false, default: 75

      t.boolean :needs_meal,       null: false, default: false
      t.boolean :needs_walk,       null: false, default: false
      t.boolean :needs_bath,       null: false, default: false
      t.boolean :is_alive,         null: false, default: true

      t.datetime :birth_date,      null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :last_interaction, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :pets, [ :user_id, :name ], unique: true
    add_index :pets, :is_alive
  end
end
