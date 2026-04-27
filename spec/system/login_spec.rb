require "rails_helper"

RSpec.describe "Login", type: :system do
  let(:password) { "SecureP@ss123" }
  let!(:user) { create(:user, email_address: FFaker::Internet.email, password: password) }

  describe "page structure" do
    before { visit new_session_path }

    it "displays the Spotsby logo" do
      expect(page).to have_css("img.auth__logo[alt='Spotsby']")
    end

    it "displays the login title" do
      expect(page).to have_css("h1.auth__title", text: "Log in to Spotsby")
    end

    it "has an email address field" do
      expect(page).to have_field("Email address", type: "email")
    end

    it "has a password field" do
      expect(page).to have_field("Password", type: "password")
    end

    it "has a Log in button" do
      expect(page).to have_button("Log in")
    end

    it "has a forgot password link" do
      expect(page).to have_link("Forgot your password?", href: new_password_path)
    end

    it "has a sign up link" do
      expect(page).to have_link("Sign up for Spotsby", href: new_registration_path)
    end

    it "wraps content in the auth card layout" do
      expect(page).to have_css("main.auth section.auth__card")
    end

    it "applies the primary button styling to the submit" do
      expect(page).to have_css("input.btn.btn--primary.btn--block.btn--uppercase.btn--lg")
    end
  end

  describe "successful login" do
    it "redirects to the root path" do
      visit new_session_path

      fill_in "Email address", with: user.email_address
      fill_in "Password", with: password
      click_button "Log in"

      expect(page).to have_current_path(root_path)
    end
  end

  describe "failed login" do
    it "shows an alert with wrong credentials" do
      visit new_session_path

      fill_in "Email address", with: user.email_address
      fill_in "Password", with: "wrongpassword"
      click_button "Log in"

      expect(page).to have_css(".flash.flash--alert", text: "Try another email address or password.")
    end
  end

  describe "navigation" do
    it "navigates to the registration page" do
      visit new_session_path
      click_link "Sign up for Spotsby"

      expect(page).to have_current_path(new_registration_path)
    end

    it "navigates to the forgot password page" do
      visit new_session_path
      click_link "Forgot your password?"

      expect(page).to have_current_path(new_password_path)
    end
  end
end
