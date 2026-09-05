module RewardService
  Result = Struct.new(:success?, :error, :coins_awarded, keyword_init: true)

  def self.claim(user)
    claim_state = user.claim_state || user.build_claim_state

    unless claim_state.eligible?
      return Result.new(
        success?: false,
        error: "Next reward available at #{claim_state.next_claim_at.iso8601}"
      )
    end

    coins = rand(ClaimState::MIN_COINS..ClaimState::MAX_COINS)

    ActiveRecord::Base.transaction do
      user.increment!(:coins, coins)
      claim_state.update!(last_claimed_at: Time.current)
    end

    Result.new(success?: true, coins_awarded: coins)
  rescue => e
    Result.new(success?: false, error: e.message)
  end
end
