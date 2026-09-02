module Api
  module V1
    class PetsController < ApplicationController
      before_action :authenticate_devise_api_token!
      before_action :set_pet, only: %i[show destroy feed walk bathe sleep play check_status]

      def index
        pets = current_devise_api_user.pets
        render json: PetBlueprint.render(pets)
      end

      def show
        PetMechanics.check_status(@pet)
        render json: PetBlueprint.render(@pet)
      end

      def create
        pet = current_devise_api_user.pets.build(pet_params)
        PetMechanics.refresh_needs_and_health(pet)
        if pet.save
          render json: PetBlueprint.render(pet), status: :created
        else
          render json: { error: pet.errors.full_messages.first }, status: :unprocessable_entity
        end
      end

      def destroy
        @pet.destroy
        render json: { message: "Pet deleted" }
      end

      def feed  = care_action { PetMechanics.feed(@pet) }
      def walk  = care_action { PetMechanics.walk(@pet) }
      def bathe = care_action { PetMechanics.bathe(@pet) }

      def sleep
        hours = params.fetch(:hours, 8).to_i
        care_action { PetMechanics.sleep(@pet, hours: hours) }
      end

      def play
        hours = params.fetch(:hours, 4).to_i
        care_action { PetMechanics.play(@pet, hours: hours) }
      end

      def check_status
        result = PetMechanics.check_status(@pet)
        if result.success?
          render json: PetBlueprint.render(@pet)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def set_pet
        @pet = current_devise_api_user.pets.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Not found" }, status: :not_found
      end

      def pet_params
        params.require(:pet).permit(:name, :species)
      end

      def care_action
        result = yield
        if result.success?
          render json: PetBlueprint.render(@pet)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end
    end
  end
end
