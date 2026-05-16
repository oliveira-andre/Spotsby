require 'rails_helper'

RSpec.describe NowPlayingController, type: :request do
  let(:user) { create(:user) }

  context 'when not signed in' do
    it 'rejects play' do
      post play_now_playing_path
      expect(response).not_to have_http_status(:no_content)
    end
  end

  context 'when signed in' do
    before { sign_in(user) }

    describe 'POST /now_playing/play' do
      it 'sets the current session as active and returns no_content' do
        expect {
          post play_now_playing_path
        }.to change { user.reload.active_session_id }.from(nil)
        expect(response).to have_http_status(:no_content)
      end
    end

    describe 'POST /now_playing/pause' do
      it 'returns no_content without touching active_session_id' do
        user.update!(active_session_id: user.sessions.first.id)
        expect {
          post pause_now_playing_path
        }.not_to change { user.reload.active_session_id }
        expect(response).to have_http_status(:no_content)
      end
    end

    describe 'PATCH /now_playing/active_device' do
      it 'flips active_session_id to the chosen session' do
        other = user.sessions.create!(user_agent: "Other", ip_address: "127.0.0.2")
        patch active_device_now_playing_path, params: { session_id: other.id }
        expect(response).to have_http_status(:no_content)
        expect(user.reload.active_session_id).to eq(other.id)
      end

      it 'will not accept a session belonging to another user' do
        other_user = create(:user)
        foreign = other_user.sessions.create!(user_agent: "X", ip_address: "127.0.0.3")
        patch active_device_now_playing_path, params: { session_id: foreign.id }
        expect(response).to have_http_status(:not_found)
        expect(user.reload.active_session_id).to be_nil
      end
    end
  end
end
