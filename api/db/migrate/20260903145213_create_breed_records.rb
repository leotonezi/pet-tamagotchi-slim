class CreateBreedRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :breed_records do |t|
      t.references :owner,     null: false, foreign_key: { to_table: :users }
      t.references :parent_a,  null: false, foreign_key: { to_table: :pets }
      t.references :parent_b,  null: false, foreign_key: { to_table: :pets }
      t.references :offspring, null: false, foreign_key: { to_table: :pets }
      t.timestamps
    end
  end
end
