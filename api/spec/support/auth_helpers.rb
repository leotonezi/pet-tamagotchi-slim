module AuthHelpers
  def auth_headers_for(user)
    token = user.access_tokens.create!(
      access_token: Devise::Api::Token.generate_uniq_access_token(user),
      refresh_token: Devise::Api::Token.generate_uniq_refresh_token(user),
      expires_in: 1.day.to_i
    )
    { "Authorization" => "Bearer #{token.access_token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
