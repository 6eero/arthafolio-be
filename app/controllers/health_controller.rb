class HealthController < ApplicationController
  skip_before_action :authenticate_request

  def show
    render json: { status: 'ok', secret_key_in_use: Rails.application.secret_key_base }, status: :ok
  end
end
