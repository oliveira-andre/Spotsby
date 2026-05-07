require 'rails_helper'

RSpec.describe Author, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:author)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:albums) }
    it { is_expected.to have_many(:song_authors) }
    it { is_expected.to have_many(:songs).through(:song_authors) }
  end

  describe 'validations' do
    subject { build(:author) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }

    it 'rejects unsupported image content types' do
      author = build(:author)
      author.image.attach(io: StringIO.new("x"), filename: "x.txt", content_type: "text/plain")
      expect(author).not_to be_valid
      expect(author.errors[:image]).to be_present
    end
  end

  describe 'cascade deletes' do
    it 'destroys associated albums and song_authors' do
      author = create(:author)
      album = create(:album, author: author)
      create(:song, album: album)

      expect { author.destroy }.to change(Album, :count).by(-1)
    end
  end

  describe 'friendly_id slug' do
    it 'sets a slug from the name' do
      author = create(:author, name: "Some Cool Artist")
      expect(author.slug).to eq("some-cool-artist")
      expect(Author.friendly.find(author.slug)).to eq(author)
    end
  end
end
