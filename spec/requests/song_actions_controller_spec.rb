require 'rails_helper'

RSpec.describe SongActionsController, type: :request do
  let(:user) { create(:user) }
  let(:song) { create(:song) }

  describe 'GET /songs/:song_id/actions' do
    context 'when signed in' do
      before { sign_in(user) }

      it 'renders the song actions frame with song details' do
        get song_actions_path(song_id: song.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("song_actions_body")
        expect(response.body).to include(song.name)
        expect(response.body).to include("Add to queue")
      end
    end
  end
end
