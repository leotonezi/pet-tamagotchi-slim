module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_devise_api_token!, only: %i[sign_out me]

      def sign_up
        user = User.new(user_params)
        token = nil
        ActiveRecord::Base.transaction do
          user.save!
          token = issue_token(user)
        end
        render json: { token: token.access_token, user: UserBlueprint.render_as_hash(user) }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.first }, status: :unprocessable_entity
      end

      def sign_in
        user = User.find_by(email: user_params[:email])
        unless user&.valid_password?(user_params[:password])
          return render json: { error: "Invalid email or password" }, status: :unauthorized
        end

        token = issue_token(user)
        render json: { token: token.access_token, user: UserBlueprint.render_as_hash(user) }
      end

      def sign_out
        current_devise_api_token.revoke!
        render json: { message: "Signed out" }
      end

      def me
        render json: UserBlueprint.render(current_devise_api_user)
      end

      private

      def user_params
        params.require(:user).permit(:email, :password)
      end

      def issue_token(user)
        user.access_tokens.create!(
          access_token: Devise::Api::Token.generate_uniq_access_token(user),
          refresh_token: Devise::Api::Token.generate_uniq_refresh_token(user),
          expires_in: 1.day.to_i
        )
      end
    end
  end
end
