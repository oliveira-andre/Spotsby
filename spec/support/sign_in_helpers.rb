module SignInHelpers
  DEFAULT_TEST_PASSWORD = "12345678".freeze

  def sign_in(user, password: nil)
    password ||= user.password.presence || DEFAULT_TEST_PASSWORD
    user.update!(password: password) unless user.authenticate(password)

    post session_path, params: { email_address: user.email_address, password: password }
    follow_redirect! if response.redirect?
  end
end

RSpec.configure do |config|
  config.include SignInHelpers, type: :request
end
