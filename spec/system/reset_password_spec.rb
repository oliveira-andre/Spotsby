require "rails_helper"

RSpec.describe "Reset Password", type: :system do
  let(:password) { "OldP@ssword123" }
  let(:new_password) { "NewSecureP@ss456" }
  let!(:user) { create(:user, email_address: FFaker::Internet.email, password: password) }

  describe "with a valid token" do
    let(:token) { user.password_reset_token }

    describe "page structure" do
      before { visit edit_password_path(token) }

      it "displays the Spotsby logo" do
        expect(page).to have_css("img.auth__logo[alt='Spotsby']")
      end

      it "displays the update password title" do
        expect(page).to have_css("h1.auth__title", text: "Update your password")
      end

      it "displays the subtitle" do
        expect(page).to have_css(".auth__subtitle", text: "Choose a new password for your account.")
      end

      it "has a new password field" do
        expect(page).to have_field("New password", type: "password")
      end

      it "has a confirm password field" do
        expect(page).to have_field("Confirm password", type: "password")
      end

      it "has an Update password button" do
        expect(page).to have_button("Update password")
      end

      it "has a log in link" do
        expect(page).to have_link("Log in", href: new_session_path)
      end

      it "wraps content in the auth card layout" do
        expect(page).to have_css("main.auth section.auth__card")
      end

      it "applies the primary button styling" do
        expect(page).to have_css("input.btn.btn--primary.btn--block.btn--uppercase.btn--lg")
      end
    end

    describe "successful password reset" do
      it "updates the password and redirects to login" do
        visit edit_password_path(token)

        fill_in "New password", with: new_password
        fill_in "Confirm password", with: new_password
        click_button "Update password"

        expect(page).to have_current_path(new_session_path)
        expect(page).to have_css(".flash.flash--notice", text: "Password has been reset.")
      end
    end

    describe "failed password reset" do
      it "shows an error when passwords don't match" do
        visit edit_password_path(token)

        fill_in "New password", with: new_password
        fill_in "Confirm password", with: password
        click_button "Update password"

        expect(page).to have_css(".flash.flash--alert", text: "Passwords did not match.")
      end
    end
  end

  describe "with an invalid token" do
    it "redirects to forgot password with an error" do
      visit edit_password_path("invalid-token-here")

      expect(page).to have_current_path(new_password_path)
      expect(page).to have_css(".flash.flash--alert", text: /invalid or has expired/)
    end
  end

  describe "navigation" do
    let(:token) { user.password_reset_token }

    it "navigates to the login page" do
      visit edit_password_path(token)
      click_link "Log in"

      expect(page).to have_current_path(new_session_path)
    end
  end
end
