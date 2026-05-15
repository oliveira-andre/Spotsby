require 'rails_helper'

RSpec.describe SongQueuesController, type: :request do
  let(:user) { create(:user) }
  let(:song) { create(:song) }

  describe 'POST /song_queues' do
    context 'when not signed in' do
      it 'does not create a queue entry' do
        expect {
          post song_queues_path, params: { song_id: song.id }
        }.not_to change { SongQueue.count }
      end
    end

    context 'when signed in' do
      before { sign_in(user) }

      it 'enqueues the selected song as user_custom' do
        expect {
          post song_queues_path, params: { song_id: song.id }
        }.to change { user.song_queues.where(source: SongQueue::SOURCE_USER_CUSTOM).count }.by(1)

        expect(user.song_queues.where(source: SongQueue::SOURCE_USER_CUSTOM).last.song).to eq(song)
      end

      it 'responds with a turbo_stream that closes the modal' do
        post song_queues_path,
             params: { song_id: song.id },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("song_actions_body")
        expect(response.body).to include("Added to queue")
      end

      it 'redirects back on html requests' do
        post song_queues_path, params: { song_id: song.id }, headers: { "Referer" => root_url }
        expect(response).to redirect_to(root_url)
      end
    end
  end
end
