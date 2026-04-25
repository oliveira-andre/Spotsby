require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_many(:authors) }
    it { is_expected.to have_many(:playlists) }
    it { is_expected.to have_many(:play_histories) }
    it { is_expected.to have_many(:song_queues) }
  end

  describe 'secure password' do
    it { is_expected.to have_secure_password }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, blocked: 1, admin: 2) }
  end

  describe 'email normalization' do
    it 'downcases and strips email_address' do
      user = create(:user, email_address: '  Foo@Example.COM  ')
      expect(user.email_address).to eq('foo@example.com')
    end
  end
end
