require "rails_helper"

RSpec.describe "Registration", type: :system do
  let(:secure_password) { "SecureP@ss123" }
  describe "page structure" do
    before { visit new_registration_path }

    it "displays the Spotsby logo" do
      expect(page).to have_css("img.auth__logo[alt='Spotsby']")
    end

    it "displays the sign up title" do
      expect(page).to have_css("h1.auth__title", text: "Sign up to start listening")
    end

    it "has an email address field" do
      expect(page).to have_field("Email address", type: "email")
    end

    it "has a password field with strength meter" do
      expect(page).to have_field("Password", type: "password")
      expect(page).to have_css(".password-strength")
      expect(page).to have_css(".password-strength__segment", count: 4)
    end

    it "has a confirm password field" do
      expect(page).to have_field("Confirm password", type: "password")
    end

    it "has a Sign up button" do
      expect(page).to have_button("Sign up")
    end

    it "has a log in link" do
      expect(page).to have_link("Log in", href: new_session_path)
    end

    it "wraps content in the auth card layout" do
      expect(page).to have_css("main.auth section.auth__card")
    end

    it "applies the primary button styling to the submit" do
      expect(page).to have_css("input.btn.btn--primary.btn--block.btn--uppercase.btn--lg")
    end
  end

  describe "successful registration" do
    it "creates a new user and redirects to root" do
      visit new_registration_path

      fill_in "Email address", with: FFaker::Internet.email
      find("input[placeholder='Create a password']").fill_in(with: secure_password)
      fill_in "Confirm password", with: secure_password
      click_button "Sign up"

      expect(page).to have_current_path(root_path)
    end
  end

  describe "failed registration" do
    it "shows validation errors with mismatched passwords" do
      visit new_registration_path

      fill_in "Email address", with: "newuser@spotsby.com"
      find("input[placeholder='Create a password']").fill_in(with: secure_password)
      fill_in "Confirm password", with: "DifferentPass456"
      click_button "Sign up"

      expect(page).to have_css(".flash.flash--alert")
    end

    it "shows validation errors without email" do
      visit new_registration_path

      find("input[placeholder='Create a password']").fill_in(with: secure_password)
      fill_in "Confirm password", with: "SecureP@ss123"
      click_button "Sign up"

      expect(page).to have_current_path(new_registration_path)
    end
  end

  describe "password strength meter" do
    def password_field
      find("input[placeholder='Create a password']")
    end

    def meter
      find(".password-strength")
    end

    def label
      find(".password-strength__label-value")
    end

    it "starts in the 'Too short' state" do
      visit new_registration_path

      expect(meter["data-strength"]).to eq("0")
      expect(label).to have_text("Too short")
    end

    it "stays 'Too short' for passwords under 8 characters" do
      visit new_registration_path

      password_field.fill_in(with: "Ab1!")

      expect(meter["data-strength"]).to eq("0")
      expect(label).to have_text("Too short")
    end

    it "marks an 8-char lowercase-only password as 'Weak'" do
      visit new_registration_path

      password_field.fill_in(with: "abcdefgh")

      expect(meter["data-strength"]).to eq("1")
      expect(label).to have_text("Weak")
    end

    it "marks a mixed-case 8-char password as 'Fair'" do
      visit new_registration_path

      password_field.fill_in(with: "abcdefgH")

      expect(meter["data-strength"]).to eq("2")
      expect(label).to have_text("Fair")
    end

    it "marks letters + digits (no symbol) as 'Good'" do
      visit new_registration_path

      password_field.fill_in(with: "Abcdefg1")

      expect(meter["data-strength"]).to eq("3")
      expect(label).to have_text("Good")
    end

    it "marks a long password with all character classes as 'Strong'" do
      visit new_registration_path

      password_field.fill_in(with: secure_password)

      expect(meter["data-strength"]).to eq("4")
      expect(label).to have_text("Strong")
    end
  end

  describe "navigation" do
    it "navigates to the login page" do
      visit new_registration_path
      click_link "Log in"

      expect(page).to have_current_path(new_session_path)
    end
  end
end
