module Api
  class SnapshotsController < ApplicationController
    before_action :authenticate_request
    before_action :ensure_system_user

    def create
      Rails.logger.info "🟢 Snapshot Job called by: #{current_user&.email}"

      # 1. Aggiorna tutti i prezzi obsoleti
      PriceUpdater.update_all_stale_prices

      # 2. Crea lo snapshot per tutti gli utenti (questo servizio può rimanere quasi uguale)
      PortfolioSnapshotService.snapshot_for_all_users

      render json: { message: 'Snapshot completato per tutti gli utenti' }, status: :ok
    end

    private

    def ensure_system_user
      head :unauthorized unless current_user&.email == 'cron@yourapp.com'
    end
  end
end