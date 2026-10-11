require 'rails_helper'

RSpec.describe Song, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(create(:song)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:album) }
    it { is_expected.to have_many(:song_authors) }
    it { is_expected.to have_many(:authors).through(:song_authors) }
    it { is_expected.to have_many(:playlist_songs) }
    it { is_expected.to have_many(:playlists).through(:playlist_songs) }
    it { is_expected.to have_many(:play_histories) }
    it { is_expected.to have_many(:users).through(:play_histories) }
  end

  describe 'validations' do
    subject { create(:song) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:album_id) }
    it { is_expected.to validate_presence_of(:category_id) }
    it { is_expected.to validate_presence_of(:album_id) }
    it { is_expected.to validate_numericality_of(:duration_ms).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:age).is_greater_than_or_equal_to(0) }

    it 'rejects unsupported image content types' do
      song = build(:song)
      song.image.attach(io: StringIO.new("x"), filename: "x.txt", content_type: "text/plain")
      expect(song).not_to be_valid
      expect(song.errors[:image]).to be_present
    end

    it 'rejects unsupported audio content types' do
      song = build(:song)
      song.audio.attach(io: StringIO.new("x"), filename: "x.txt", content_type: "text/plain")
      expect(song).not_to be_valid
      expect(song.errors[:audio]).to be_present
    end

    it 'is valid without an audio attachment' do
      song = build(:song, album: create(:album), category: create(:category))
      expect(song).to be_valid
    end
  end

  describe '.ordered' do
    it 'returns songs by ascending position' do
      album = create(:album)
      a = create(:song, name: "A track", album: album)
      b = create(:song, name: "B track", album: album)
      c = create(:song, name: "C track", album: album)
      a.update!(position: 3)
      b.update!(position: 1)
      c.update!(position: 2)

      expect(Song.where(album: album).ordered).to eq([ b, c, a ])
    end
  end

  describe 'destroying cascades' do
    it 'destroys song_authors links' do
      song = create(:song)
      song.authors << create(:author)

      expect { song.destroy }.to change(SongAuthor, :count).by(-1)
    end
  end

  describe 'friendly_id slug' do
    it 'creates a slug from the name' do
      song = create(:song, name: "My New Song", album: create(:album))
      expect(song.slug).to eq("my-new-song")
      expect(Song.friendly.find(song.slug)).to eq(song)
    end
  end

  describe 'user-modification guard' do
    let(:song) { create(:song) }
    let(:regular_user) { create(:user, status: :active) }
    let(:admin_user) { create(:user, status: :admin) }
    let(:session) { Session.new(user: user) }

    around do |example|
      Current.set(session: session) { example.run }
    end

    context 'as a regular user' do
      let(:user) { regular_user }

      it 'raises ReadOnlyRecord on update' do
        expect { song.update!(name: 'Different') }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end

    context 'as an admin user' do
      let(:user) { admin_user }

      it 'allows the update' do
        expect { song.update!(name: 'Different') }.not_to raise_error
      end
    end

    context 'with no Current.session (job context)' do
      let(:session) { nil }

      around do |example|
        Current.set(session: nil) { example.run }
      end

      it 'allows the update' do
        expect { song.update!(name: 'Different') }.not_to raise_error
      end
    end
  end

  describe 'audio_fragment job enqueue' do
    let(:fixture_path) { Rails.root.join('spec/fixtures/files/sample.mp3') }

    it 'enqueues GenerateInitialFragmentJob when audio is attached and fragment is missing' do
      song = create(:song)
      expect {
        song.audio.attach(io: File.open(fixture_path, 'rb'), filename: 'sample.mp3', content_type: 'audio/mpeg')
      }.to have_enqueued_job(GenerateInitialFragmentJob).with(song.id)
    end

    it 'does not enqueue when no audio is attached' do
      expect { create(:song) }.not_to have_enqueued_job(GenerateInitialFragmentJob)
    end
  end

  describe 'search text' do
    let(:author) { create(:author, name: 'Night Owls') }
    let(:album) { create(:album, name: 'Midnight Drive', author: author) }
    let(:song) { create(:song, name: 'Neon Lights', album: album) }

    before { create(:song_author, song: song, author: author) }

    it 'compiles the song, album and author names, lowercased' do
      expect(song.reload.search_text).to eq('neon lights midnight drive night owls')
    end

    it 'leaves playlist names out' do
      create(:playlist_song, song: song, playlist: create(:playlist, name: 'Road Trip', status: :public))
      expect(song.reload.search_text).not_to include('road trip')
    end

    it 'follows a song rename' do
      song.update!(name: 'Neon Nights')
      expect(song.reload.search_text).to start_with('neon nights')
    end

    it 'follows an album rename' do
      album.update!(name: 'Dawn Patrol')
      expect(song.reload.search_text).to include('dawn patrol')
      expect(song.search_text).not_to include('midnight drive')
    end

    it 'follows an author rename' do
      author.update!(name: 'Early Birds')
      expect(song.reload.search_text).to include('early birds')
      expect(song.search_text).not_to include('night owls')
    end

    # The admin forms save the song first and assign `author_ids` afterwards.
    it 'includes authors assigned after the song was saved' do
      fresh = create(:song, name: 'Late Arrival', album: album)
      guest = create(:author, name: 'Guest Star')

      fresh.author_ids = [ author.id, guest.id ]

      expect(fresh.reload.search_text).to include('night owls', 'guest star')
    end

    it 'follows authors being replaced' do
      guest = create(:author, name: 'Guest Star')
      song.update!(author_ids: [ guest.id ])

      expect(song.reload.search_text).to include('guest star')
      expect(song.search_text).not_to include('night owls')
    end
  end

  describe '.search' do
    let(:author) { create(:author, name: 'Night Owls') }
    let(:album) { create(:album, name: 'Midnight Drive', author: author) }
    let!(:song) { create(:song, name: 'Neon Lights', album: album) }
    let!(:other) { create(:song, name: 'Quiet Harbor') }

    before { create(:song_author, song: song, author: author) }

    it 'finds a song by its own, album or author name' do
      [ 'neon lights', 'midnight drive', 'night owls' ].each do |query|
        expect(described_class.search(query)).to contain_exactly(song), "expected #{query.inspect} to find the song"
      end
    end

    it 'ignores case, surrounding spaces and small typos' do
      expect(described_class.search('  NEON  ')).to include(song)
      expect(described_class.search('midnite drive')).to include(song)
    end

    it 'does not match on a playlist name' do
      create(:playlist_song, song: song, playlist: create(:playlist, name: 'Road Trip', status: :public))
      expect(described_class.search('road trip')).to be_empty
    end

    it 'puts the closest match first' do
      close = create(:song, name: 'Harbor Lights')
      expect(described_class.search('harbor lights').first).to eq(close)
    end

    it 'returns at most 20 songs' do
      21.times { |i| create(:song, name: "Track #{i}", album: album) }
      expect(described_class.search('midnight drive').size).to eq(20)
    end
  end
end
