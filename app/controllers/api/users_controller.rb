module Api
  class UsersController < ApplicationController
    def who_am_i
      render json: {
        email: current_user.email
      }
    end
  end
end
