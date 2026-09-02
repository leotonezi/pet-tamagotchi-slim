class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :validatable, :api

  validates :coins, numericality: { greater_than_or_equal_to: 0 }
end
