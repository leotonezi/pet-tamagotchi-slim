class ClaimState < ApplicationRecord
  belongs_to :user

  COOLDOWN = 24.hours
  MIN_COINS = 10
  MAX_COINS = 25

  def eligible?
    last_claimed_at.nil? || last_claimed_at < COOLDOWN.ago
  end

  def next_claim_at
    return Time.current if eligible?
    last_claimed_at + COOLDOWN
  end
end
