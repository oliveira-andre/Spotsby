require 'rails_helper'

RSpec.describe Admin::DashboardController, type: :request do
  describe 'GET /admin/dashboard' do
    context 'when not authenticated' do
      it 'redirects to login' do
        get admin_dashboard_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when authenticated as a regular user' do
      let(:user) { create(:user) }

      it 'returns 401 unauthorized' do
        sign_in(user)
        get admin_dashboard_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as an admin' do
      let(:admin) { create(:user, status: :admin) }

      it 'renders the dashboard' do
        sign_in(admin)
        get admin_dashboard_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
