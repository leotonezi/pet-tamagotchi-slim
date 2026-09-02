class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :validatable, :api

  has_many :pets, dependent: :destroy
  has_one  :inventory, dependent: :destroy

  after_create :create_inventory

  validates :coins, numericality: { greater_than_or_equal_to: 0 }
end
