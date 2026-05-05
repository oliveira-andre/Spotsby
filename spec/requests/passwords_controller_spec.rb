require 'rails_helper'

RSpec.describe PasswordsController, type: :request do
  describe 'GET /passwords/new' do
    it 'renders the request form' do
      get new_password_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /passwords' do
    let!(:user) { create(:user) }

    it 'enqueues a reset email and redirects to login' do
      expect {
        post passwords_path, params: { email_address: user.email_address }
      }.to have_enqueued_mail(PasswordsMailer, :reset).with(user)

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to be_present
    end

    it 'redirects with the same notice when the email is unknown (no enumeration)' do
      expect {
        post passwords_path, params: { email_address: 'nobody@example.com' }
      }.not_to have_enqueued_mail(PasswordsMailer, :reset)

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to be_present
    end
  end

  describe 'GET /passwords/:token/edit' do
    let(:user) { create(:user) }

    it 'renders the edit form for a valid token' do
      get edit_password_path(user.password_reset_token)
      expect(response).to have_http_status(:ok)
    end

    it 'redirects when the token is invalid' do
      get edit_password_path('not-a-real-token')
      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe 'PATCH /passwords/:token' do
    let(:user) { create(:user) }

    it 'updates the password when confirmation matches' do
      old_digest = user.password_digest
      patch password_path(user.password_reset_token),
            params: { password: 'newsecret', password_confirmation: 'newsecret' }

      expect(response).to redirect_to(new_session_path)
      expect(user.reload.password_digest).not_to eq(old_digest)
    end

    it 'redirects back to edit when confirmation does not match' do
      old_digest = user.password_digest
      token = user.password_reset_token

      patch password_path(token),
            params: { password: 'newsecret', password_confirmation: 'mismatch' }

      expect(response).to redirect_to(edit_password_path(token))
      expect(flash[:alert]).to be_present
      expect(user.reload.password_digest).to eq(old_digest)
    end
  end
end
