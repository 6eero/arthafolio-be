module Api
  class UsersController < ApplicationController
    def who_am_i
      render json: user_identity
    end

    def update_preferences
      if current_user.update(preferences_params)
        render json: user_identity, status: :ok
      else
        render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def user_identity
      {
        email: current_user.email,
        username: current_user.username,
        hide_holdings: current_user.hide_holdings,
        preferred_currency: current_user.preferred_currency
      }
    end

    def preferences_params
      params.permit(:preferred_currency, :hide_holdings)
    end
  end
end
