require 'rails_helper'

RSpec.describe NowPlayingChannel, type: :channel do
  let(:user) { create(:user, password: "12345678") }
  let(:session) { user.sessions.create!(user_agent: "Test/1.0", ip_address: "127.0.0.1") }

  before do
    stub_connection current_user: user
    allow_any_instance_of(described_class).to receive(:current_session).and_return(session)
  end

  describe '#subscribed' do
    it 'touches the session last_seen_at' do
      expect { subscribe }.to change { session.reload.last_seen_at }.from(nil)
    end

    context 'when this is the only recently-active session' do
      it 'auto-activates it' do
        expect { subscribe }.to change { user.reload.active_session_id }.from(nil).to(session.id)
      end
    end

    context 'when another session is already active' do
      let(:other_session) do
        other = user.sessions.create!(user_agent: "Other/1.0", ip_address: "127.0.0.2")
        other.update!(last_seen_at: 30.seconds.ago)
        other
      end

      it 'does not steal active from the other session' do
        user.update!(active_session_id: other_session.id)
        subscribe
        expect(user.reload.active_session_id).to eq(other_session.id)
      end
    end

    it 'is subscribed to a stream for the user' do
      subscribe
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(user)
    end
  end

  describe '#heartbeat' do
    it 'refreshes last_seen_at' do
      subscribe
      session.update_column(:last_seen_at, 10.minutes.ago)
      expect { perform :heartbeat }.to change { session.reload.last_seen_at }
    end
  end
end
