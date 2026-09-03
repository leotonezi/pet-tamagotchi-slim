module Api
  module V1
    class BreedController < ApplicationController
      before_action :authenticate_devise_api_token!

      def create
        result = BreedService.breed(
          user:          current_devise_api_user,
          parent_a_id:   params.require(:parent_a_id).to_i,
          parent_b_id:   params.require(:parent_b_id).to_i,
          offspring_name: params.require(:name)
        )

        if result.success?
          render json: PetBlueprint.render(result.offspring), status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end
    end
  end
end
