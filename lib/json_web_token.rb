module JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base

  def jwt_encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def jwt_decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError => e
    raise StandardError, "Invalid token: #{e.message}"
  end
end
