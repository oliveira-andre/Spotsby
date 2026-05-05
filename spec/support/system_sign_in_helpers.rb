module SystemSignInHelpers
  DEFAULT_TEST_PASSWORD = "12345678".freeze

  def sign_in_as(user, password: DEFAULT_TEST_PASSWORD)
    user.update!(password: password)

    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password",      with: password
    click_button "Log in"
    expect(page).to have_no_current_path(new_session_path, wait: 5)
  end
end

RSpec.configure do |config|
  config.include SystemSignInHelpers, type: :system
end
