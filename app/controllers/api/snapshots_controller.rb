module Api
  class SnapshotsController < ApplicationController
    before_action :authenticate_request
    before_action :ensure_system_user

    def create
      Rails.logger.info "🟢 Called by: #{current_user&.email}"
      PortfolioSnapshotService.snapshot_for_all_users
      render json: { message: 'Snapshot completato' }, status: :ok
    end

    private

    def ensure_system_user
      head :unauthorized unless current_user&.email == 'cron@yourapp.com'
    end
  end
end
