class AddActiveActionToPets < ActiveRecord::Migration[8.1]
  def change
    add_column :pets, :active_action, :string
    add_column :pets, :action_ends_at, :datetime
  end
end
