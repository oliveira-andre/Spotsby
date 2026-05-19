require 'rails_helper'

RSpec.describe PlaylistCloning do
  let(:owner) { create(:user) }
  let(:cloner) { create(:user) }
  let(:source) { create(:playlist, user: owner, status: :public, name: "Source") }
  subject(:service) { described_class.new(user: cloner, source: source) }

  describe '#call' do
    it 'creates a private playlist owned by the cloner' do
      clone = service.call

      expect(clone).to be_persisted
      expect(clone.user).to eq(cloner)
      expect(clone.status).to eq("private")
    end

    it 'reuses the source name when the cloner has no name collision' do
      clone = service.call
      expect(clone.name).to eq("Source")
    end

    it 'appends "(Copy)" when the cloner already has a playlist with that name' do
      create(:playlist, user: cloner, name: "Source")
      clone = service.call
      expect(clone.name).to eq("Source (Copy)")
    end

    it 'increments the suffix on repeated collisions' do
      create(:playlist, user: cloner, name: "Source")
      create(:playlist, user: cloner, name: "Source (Copy)")
      clone = service.call
      expect(clone.name).to eq("Source (Copy 2)")
    end

    it 'copies the source songs preserving order and position' do
      song_a = create(:song)
      song_b = create(:song)
      song_c = create(:song)
      create(:playlist_song, playlist: source, song: song_a, position: 1)
      create(:playlist_song, playlist: source, song: song_b, position: 2)
      create(:playlist_song, playlist: source, song: song_c, position: 3)

      clone = service.call

      cloned = clone.playlist_songs.ordered
      expect(cloned.pluck(:song_id, :position)).to eq([
        [ song_a.id, 1 ],
        [ song_b.id, 2 ],
        [ song_c.id, 3 ]
      ])
    end

    it 'does not assign position 0 to the new playlist' do
      clone = service.call
      expect(clone.position).to be > 0
    end

    it 'leaves the source playlist untouched' do
      song = create(:song)
      create(:playlist_song, playlist: source, song: song, position: 1)

      expect {
        service.call
      }.not_to change { source.reload.attributes.slice("name", "status", "user_id", "position") }

      expect(source.playlist_songs.count).to eq(1)
    end

    context 'when the source has an attached image' do
      before do
        source.image.attach(
          io: StringIO.new("fake-image-bytes"),
          filename: "cover.jpg",
          content_type: "image/jpeg"
        )
      end

      it 'attaches a duplicated image to the clone with a different blob' do
        clone = service.call

        expect(clone.image).to be_attached
        expect(clone.image.blob.id).not_to eq(source.image.blob.id)
        expect(clone.image.filename.to_s).to eq("cover.jpg")
        expect(clone.image.content_type).to eq("image/jpeg")
        expect(clone.image.download).to eq(source.image.download)
      end
    end

    context 'when the source has no image' do
      it 'leaves the clone without an attached image' do
        clone = service.call
        expect(clone.image).not_to be_attached
      end
    end

    it 'rolls back the new playlist when copying a song fails' do
      song = create(:song)
      create(:playlist_song, playlist: source, song: song, position: 1)

      # Force the second `playlist_songs.create!` (the clone's first song copy)
      # to raise, while still letting the source preload its existing rows.
      call_count = 0
      allow_any_instance_of(ActiveRecord::Associations::CollectionProxy)
        .to receive(:create!).and_wrap_original do |orig, *args|
        call_count += 1
        raise ActiveRecord::RecordInvalid.new(PlaylistSong.new) if call_count == 1
        orig.call(*args)
      end

      expect {
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      }.not_to change { cloner.playlists.count }
    end
  end
end
