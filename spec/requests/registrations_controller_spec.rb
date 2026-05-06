require 'rails_helper'

RSpec.describe RegistrationsController, type: :request do
  describe 'GET /registration/new' do
    it 'renders the sign-up form' do
      get new_registration_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /registration' do
    context 'with valid params' do
      let(:valid_params) do
        {
          user: {
            email_address: 'newcomer@example.com',
            password: 'secret123',
            password_confirmation: 'secret123'
          }
        }
      end

      it 'creates a user and starts a session' do
        expect {
          post registration_path, params: valid_params
        }.to change { User.count }.by(1)
         .and change { Session.count }.by(1)

        expect(response).to redirect_to(root_url)
      end

      it 'normalizes the email address' do
        post registration_path, params: {
          user: {
            email_address: '  Mixed@Case.com ',
            password: 'secret123',
            password_confirmation: 'secret123'
          }
        }
        expect(User.last.email_address).to eq('mixed@case.com')
      end
    end

    context 'with invalid params' do
      it 're-renders the form with an error flash' do
        expect {
          post registration_path, params: {
            user: {
              email_address: 'bad@example.com',
              password: 'a',
              password_confirmation: 'b'
            }
          }
        }.not_to change { User.count }

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash.now[:alert]).to be_present
      end
    end
  end
end
