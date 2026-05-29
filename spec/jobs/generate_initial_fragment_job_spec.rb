require 'rails_helper'

RSpec.describe GenerateInitialFragmentJob, type: :job do
  let(:fixture_path) { Rails.root.join('spec/fixtures/files/sample.mp3') }
  let(:song) { create(:song) }

  before do
    song.audio.attach(io: File.open(fixture_path, 'rb'), filename: 'sample.mp3', content_type: 'audio/mpeg')
  end

  it 'attaches the audio_fragment when missing' do
    expect {
      described_class.perform_now(song.id)
    }.to change { song.reload.audio_fragment.attached? }.from(false).to(true)
  end

  it 'is idempotent when the fragment is already attached' do
    described_class.perform_now(song.id)
    expect(AudioFragmentClipper).not_to receive(:call)
    described_class.perform_now(song.id)
  end

  it 'is a no-op when the song has no audio' do
    song_without_audio = create(:song)
    expect(AudioFragmentClipper).not_to receive(:call)
    described_class.perform_now(song_without_audio.id)
    expect(song_without_audio.reload.audio_fragment.attached?).to be(false)
  end

  it 'tolerates a missing song' do
    expect { described_class.perform_now('00000000-0000-0000-0000-000000000000') }.not_to raise_error
  end
end
