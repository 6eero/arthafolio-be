module Api
  class RegistrationsController < ApplicationController
    skip_before_action :authenticate_request

    def create
      user = User.new(user_params)

      if user.save
        UserMailer.confirmation_email(user).deliver_now
        render json: { message: 'Registrazione completata. Controlla la tua email per confermare l’account.' },
               status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def confirm_email
      user = User.find_by(confirmation_token: params[:token])

      if user&.confirmed?
        render json: { error: 'Email già confermata.' }, status: :unprocessable_entity
      elsif user
        user.confirm!
        render json: { message: 'Email confermata con successo. Ora puoi effettuare il login.' }, status: :ok
      else
        render json: { error: 'Token non valido o utente non trovato.' }, status: :not_found
      end
    end

    private

    def user_params
      params.expect(user: %i[email username password password_confirmation])
    end
  end
end
