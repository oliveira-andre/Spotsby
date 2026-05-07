require 'rails_helper'

RSpec.describe Album, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(create(:album)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:author) }
  end

  describe 'validations' do
    subject { create(:album) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:author_id) }
    it { is_expected.to validate_presence_of(:release_date) }
    it { is_expected.to validate_presence_of(:category_id) }
    it { is_expected.to validate_presence_of(:author_id) }

    it 'rejects unsupported image content types' do
      album = build(:album)
      album.image.attach(io: StringIO.new("x"), filename: "x.txt", content_type: "text/plain")
      expect(album).not_to be_valid
      expect(album.errors[:image]).to be_present
    end
  end

  describe '.ordered' do
    it 'returns albums ordered by their position in the author scope' do
      author = create(:author)
      first = create(:album, author: author)
      second = create(:album, author: author)
      third = create(:album, author: author)

      expect(author.albums.ordered).to eq([ first, second, third ])
    end
  end

  describe 'songs association' do
    it 'returns songs ordered by position via the ordered scope on songs' do
      album = create(:album)
      a = create(:song, album: album)
      b = create(:song, album: album)
      c = create(:song, album: album)
      a.update!(position: 3)
      b.update!(position: 1)
      c.update!(position: 2)

      expect(album.reload.songs).to eq([ b, c, a ])
    end

    it 'destroys songs when the album is destroyed' do
      album = create(:album)
      create(:song, album: album)
      expect { album.destroy }.to change(Song, :count).by(-1)
    end
  end
end
