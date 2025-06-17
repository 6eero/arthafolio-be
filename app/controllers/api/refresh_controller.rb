# app/controllers/api/refresh_controller.rb

module Api
  class RefreshController < ApplicationController
    include JsonWebToken

    def create
      # Prende il refresh_token e l'access_token (scaduto) dalla richiesta
      refresh_token = params[:refresh_token]
      old_access_token = params[:access_token]

      # Decodifica il vecchio access token per ottenere l'ID utente senza verificare la scadenza
      begin
        decoded_token = jwt_decode(old_access_token)
        user_id = decoded_token[:user_id]
      rescue JWT::ExpiredSignature, JWT::DecodeError
        render json: { error: 'Invalid access token' }, status: :unauthorized
        return
      end

      # Cerca l'utente e verifica che il refresh token corrisponda
      @user = User.find_by(id: user_id, refresh_token: refresh_token)

      if @user
        # Se l'utente e il token sono validi, genera una nuova coppia di token
        new_access_token = jwt_encode({ user_id: @user.id }, 1.hour.from_now)
        new_refresh_token = SecureRandom.hex(32)
        @user.update(refresh_token: new_refresh_token)

        render json: {
          access_token: new_access_token,
          refresh_token: new_refresh_token
        }, status: :ok
      else
        render json: { error: 'Invalid refresh token' }, status: :unauthorized
      end
    end
  end
end
