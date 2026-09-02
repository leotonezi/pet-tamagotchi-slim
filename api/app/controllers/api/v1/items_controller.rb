module Api
  module V1
    class ItemsController < ApplicationController
      before_action :authenticate_devise_api_token!

      def index
        render json: ItemBlueprint.render(Item.all)
      end
    end
  end
end
