class Pet < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, length: { maximum: 32 },
                   uniqueness: { scope: :user_id, case_sensitive: false }
  validates :species, presence: true, length: { maximum: 16 }
  validates :hunger, :tiredness, :hygiene, :happiness, :health,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
