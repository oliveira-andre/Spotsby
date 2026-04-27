require "rails_helper"

RSpec.describe "Forgot Password", type: :system do
  let(:no_existing_email) { "nobody@spotsby.com" }
  let!(:user) { create(:user, email_address: FFaker::Internet.email) }

  describe "page structure" do
    before { visit new_password_path }

    it "displays the Spotsby logo" do
      expect(page).to have_css("img.auth__logo[alt='Spotsby']")
    end

    it "displays the forgot password title" do
      expect(page).to have_css("h1.auth__title", text: "Forgot your password?")
    end

    it "displays the subtitle" do
      expect(page).to have_css(".auth__subtitle", text: "We'll email you a link to reset it.")
    end

    it "has an email address field" do
      expect(page).to have_field("Email address", type: "email")
    end

    it "has a Send button" do
      expect(page).to have_button("Send")
    end

    it "has a log in link" do
      expect(page).to have_link("Log in", href: new_session_path)
    end

    it "wraps content in the auth card layout" do
      expect(page).to have_css("main.auth section.auth__card")
    end

    it "applies the primary button styling" do
      expect(page).to have_css("button.btn.btn--primary.btn--block.btn--uppercase.btn--lg")
    end
  end

  describe "submitting the form" do
    it "redirects to login with a notice for existing email" do
      visit new_password_path

      fill_in "Email address", with: user.email_address
      click_button "Send"

      expect(page).to have_current_path(new_session_path)
      expect(page).to have_css(".flash.flash--notice", text: /Password reset instructions sent/)
    end

    it "redirects to login with a notice for non-existing email" do
      visit new_password_path

      fill_in "Email address", with: no_existing_email
      click_button "Send"

      expect(page).to have_current_path(new_session_path)
      expect(page).to have_css(".flash.flash--notice", text: /Password reset instructions sent/)
    end
  end

  describe "navigation" do
    it "navigates to the login page" do
      visit new_password_path
      click_link "Log in"

      expect(page).to have_current_path(new_session_path)
    end
  end
end
