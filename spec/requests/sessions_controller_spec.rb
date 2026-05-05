require 'rails_helper'

RSpec.describe SessionsController, type: :request do
  describe 'GET /session/new' do
    it 'renders the sign-in form' do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /session' do
    let(:password) { 'secret123' }
    let!(:user) { create(:user, password: password) }

    context 'with valid credentials' do
      it 'starts a session and redirects to root' do
        expect {
          post session_path, params: { email_address: user.email_address, password: password }
        }.to change { user.sessions.count }.by(1)

        expect(response).to redirect_to(root_url)
      end
    end

    context 'with invalid credentials' do
      it 'does not create a session and redirects back to login' do
        expect {
          post session_path, params: { email_address: user.email_address, password: 'wrong' }
        }.not_to change { Session.count }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'DELETE /session' do
    let(:user) { create(:user) }

    it 'terminates the session and redirects to login' do
      sign_in(user)

      expect {
        delete session_path
      }.to change { user.sessions.count }.by(-1)

      expect(response).to redirect_to(new_session_path)
    end
  end
end
