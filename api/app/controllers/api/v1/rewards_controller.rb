module Api
  module V1
    class RewardsController < ApplicationController
      before_action :authenticate_devise_api_token!

      def show
        claim_state = current_devise_api_user.claim_state || current_devise_api_user.build_claim_state
        render json: {
          eligible:      claim_state.eligible?,
          next_claim_at: claim_state.next_claim_at.iso8601,
          last_claimed_at: claim_state.last_claimed_at&.iso8601
        }
      end

      def claim
        result = RewardService.claim(current_devise_api_user)
        if result.success?
          render json: {
            coins_awarded: result.coins_awarded,
            total_coins:   current_devise_api_user.reload.coins
          }
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end
    end
  end
end
