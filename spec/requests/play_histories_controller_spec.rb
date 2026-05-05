require 'rails_helper'

RSpec.describe PlayHistoriesController, type: :request do
  let(:user) { create(:user) }
  let(:turbo_headers) { { 'Accept' => 'text/vnd.turbo-stream.html' } }

  before { sign_in(user) }

  describe 'DELETE /play_histories/:id' do
    it 'destroys the user play history record' do
      history = create(:play_history, user: user)

      expect {
        delete play_history_path(history), headers: turbo_headers
      }.to change { user.play_histories.count }.by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'does not destroy another user play history' do
      other_history = create(:play_history)

      expect {
        delete play_history_path(other_history), headers: turbo_headers
      }.not_to change { PlayHistory.exists?(other_history.id) }.from(true)

      expect(response).to have_http_status(:not_found)
    end
  end
end
