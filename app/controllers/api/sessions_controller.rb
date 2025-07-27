# app/controllers/api/sessions_controller.rb

module Api
  class SessionsController < ApplicationController
    # Includiamo il nostro gestore di JWT
    include JsonWebToken

    # Saltiamo la verifica del token di autenticazione solo per l'azione di login
    # Se usi `before_action :authenticate_request` in ApplicationController, dovrai aggiungere questa riga.
    # skip_before_action :authenticate_request, only: [:login]
    skip_before_action :authenticate_request, only: [:login]

    def login
      # 1. Accetta un parametro generico :login dal frontend e cerca l'utente per email o per username
      login_param = params[:username_or_email]&.downcase
      @user = User.find_by(email: login_param) || User.find_by(username: login_param)

      # 2. Verifica che l'utente esista e che la password sia corretta
      if @user&.authenticate(params[:password])

        # 3. Se l'autenticazione ha successo, genera l'access token (vita breve) e refresh token sicuro e univoco (vita lunga)
        access_token = jwt_encode({ user_id: @user.id }, 30.minutes.from_now)
        refresh_token = SecureRandom.hex(32)

        # 4. Salva il refresh token nel database per l'utente
        # Questo permette di invalidarlo se necessario (es. logout da tutti i dispositivi)
        @user.update(refresh_token: refresh_token)

        # 5. Restituisce i token al frontend
        render json: {
          access_token: access_token,
          refresh_token: refresh_token
        }, status: :ok
      else
        # 6. Se l'autenticazione fallisce, restituisce un errore
        render json: { error: 'Invalid email or password', message: 'invalid_email_or_password' }, status: :unauthorized
      end
    end

    def logout
      # Rimuove il refresh token dal DB
      current_user.update(refresh_token: nil)

      render json: { message: 'Logout successful' }, status: :ok
    end
  end
end
