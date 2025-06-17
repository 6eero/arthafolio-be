# frozen_string_literal: true

require 'jwt'

module JsonWebToken
  extend ActiveSupport::Concern

  # Usa la chiave segreta di Rails per firmare i token
  SECRET_KEY = Rails.application.credentials.secret_key_base

  def jwt_encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def jwt_decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    ActiveSupport::HashWithIndifferentAccess.new(decoded)
  end
end
