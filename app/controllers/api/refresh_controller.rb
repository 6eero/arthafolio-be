# app/controllers/api/refresh_controller.rb
module Api
  class RefreshController < ApplicationController
    include JsonWebToken

    # Non è necessario autenticare questa richiesta con un access token
    # perché l'obiettivo è proprio ottenerne uno nuovo.
    skip_before_action :authenticate_request, only: [:create]

    def create
      refresh_token = params[:refresh_token]
      old_access_token = params[:access_token] # Opzionale, utile per invalidare il precedente se necessario

      # 1. Trova l'utente associato al refresh token
      # Assumiamo che tu abbia un campo `refresh_token` nel tuo modello `User`.
      # È fondamentale che questo refresh token sia univoco per utente e non riutilizzabile dopo l'uso.
      @user = User.find_by(refresh_token: refresh_token)

      if @user
        # 2. Verifica se il refresh token è ancora valido o se ha una scadenza
        # Qui potresti aggiungere una logica per controllare la scadenza del refresh_token
        # (se lo memorizzi con una data di scadenza nel DB)
        # Per semplicità, in questo esempio ci basiamo solo sulla sua esistenza e validità.

        # 3. Genera un nuovo access token
        new_access_token = jwt_encode({ user_id: @user.id }, 1.minute.from_now) # Imposta una scadenza breve

        # 4. Genera un nuovo refresh token per maggiore sicurezza (one-time use)
        # Questo invalida il refresh token precedente, forzando l'uso di quello nuovo.
        new_refresh_token = SecureRandom.hex(32)
        @user.update(refresh_token: new_refresh_token) # Aggiorna il refresh token nel DB

        render json: {
          access_token: new_access_token,
          refresh_token: new_refresh_token # Restituisce il nuovo refresh token
        }, status: :ok
      else
        # 5. Se il refresh token non è valido o l'utente non viene trovato,
        # significa che la sessione è scaduta o il token è stato revocato.
        # È buona pratica forzare il logout del client in questo caso.
        render json: { error: 'Invalid refresh token' }, status: :unauthorized
      end
    end
  end
end