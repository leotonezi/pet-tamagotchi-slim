module Api
  module V1
    class InventoryController < ApplicationController
      before_action :authenticate_devise_api_token!

      def show
        render json: InventoryBlueprint.render(current_devise_api_user.inventory)
      end

      def buy
        item = Item.find(params[:item_id])
        qty  = params.fetch(:qty, 1).to_i
        result = ShopService.buy(user: current_devise_api_user, item: item, qty: qty)

        if result.success?
          render json: InventoryBlueprint.render(current_devise_api_user.inventory)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def use
        item = Item.find(params[:item_id])
        pet  = current_devise_api_user.pets.find(params[:pet_id])
        result = ShopService.use(user: current_devise_api_user, item: item, pet: pet)

        if result.success?
          render json: PetBlueprint.render(pet.reload)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Not found" }, status: :not_found
      end
    end
  end
end
