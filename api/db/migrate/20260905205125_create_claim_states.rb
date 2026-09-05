class CreateClaimStates < ActiveRecord::Migration[8.1]
  def change
    create_table :claim_states do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.datetime :last_claimed_at

      t.timestamps
    end
  end
end
