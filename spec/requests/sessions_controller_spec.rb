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

    context 'with a blocked account' do
      it 'rejects the right password with the generic failure and does not count it' do
        user.update!(status: :blocked)

        post session_path, params: { email_address: user.email_address, password: password }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq('Try another email address or password.')
        expect(user.sessions).to be_empty
        expect(user.reload.failed_login_attempts).to eq(0)
      end
    end

    context 'with an unknown email' do
      it 'gives the same generic failure' do
        post session_path, params: { email_address: 'nobody@example.com', password: 'wrong' }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq('Try another email address or password.')
      end
    end
  end

  describe 'account lockout' do
    let(:password) { 'password123' }
    let(:user) { create(:user, status: :admin, password: password) }

    def attempt(pass)
      post session_path, params: { email_address: user.email_address, password: pass }
    end

    it 'a correct password before the limit signs in and resets the counter' do
      (User::LOGIN_MAX_ATTEMPTS - 1).times { attempt('wrong') }

      attempt(password)

      expect(response).to redirect_to(root_url)
      expect(user.reload.failed_login_attempts).to eq(0)
    end

    it 'locks on the limit, then rejects even the right password' do
      (User::LOGIN_MAX_ATTEMPTS - 1).times { attempt('wrong') }
      expect { attempt('wrong') }.to have_enqueued_mail(PasswordsMailer, :unlock)

      attempt(password)

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq('Try another email address or password.')
      expect(user.sessions).to be_empty
    end

    it 'resetting the password through the reset link unlocks (status kept)' do
      User::LOGIN_MAX_ATTEMPTS.times { attempt('wrong') }
      expect(user.reload).to be_login_locked

      put password_path(user.password_reset_token),
          params: { password: 'brand-new-pass1', password_confirmation: 'brand-new-pass1' }

      post session_path, params: { email_address: user.email_address, password: 'brand-new-pass1' }

      expect(response).to redirect_to(root_url)
      expect(user.reload).to be_admin
      expect(user).not_to be_login_locked
    end
  end

  # The test env uses :null_store, whose `increment` returns nil, so limits
  # never trip. Route the limiter's counter into a real store for these
  # examples only. Each ends on a correct password that must be rejected, so
  # it fails loudly if the limiter isn't really firing.
  describe 'rate limits' do
    let(:password) { 'password123' }
    let(:user) { create(:user, password: password) }
    let(:store) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(SessionsController.cache_store).to receive(:increment) do |*args, **opts|
        store.increment(*args, **opts)
      end
    end

    def attempt(email, pass, ip:)
      post session_path, params: { email_address: email, password: pass }, env: { 'REMOTE_ADDR' => ip }
    end

    it 'throttles one IP after 10 attempts with the generic failure' do
      10.times { |i| attempt("probe#{i}@example.com", 'wrong', ip: '198.51.100.7') }

      attempt(user.email_address, password, ip: '198.51.100.7')
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq('Try another email address or password.')
      expect(user.sessions).to be_empty

      attempt(user.email_address, password, ip: '198.51.100.8')
      expect(response).to redirect_to(root_url)
    end

    it 'throttles one email after 5 attempts even from a new IP each time' do
      5.times { |i| attempt(user.email_address, 'wrong', ip: "192.0.2.#{i + 1}") }

      attempt(user.email_address.upcase, password, ip: '192.0.2.99')

      expect(response).to redirect_to(new_session_path)
      expect(user.sessions).to be_empty
      # Throttled requests never reach the action, so they don't count.
      expect(user.reload.failed_login_attempts).to eq(5)
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
