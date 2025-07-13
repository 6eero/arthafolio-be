require Rails.root.join('app/controllers/concerns/json_web_token')

module JwtHelpers
  def generate_token_for(user, exp: 1.hour.from_now)
    payload = { user_id: user.id, exp: exp.to_i }
    JsonWebToken.encode(payload)
  end

  def auth_headers_for(user)
    {
      'Authorization' => "Bearer #{generate_token_for(user)}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
end
