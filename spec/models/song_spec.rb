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
end
