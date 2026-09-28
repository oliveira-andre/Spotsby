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

  describe 'sign-in lockout' do
    def fail_logins(user, times)
      times.times { user.register_failed_login! }
    end

    it 'counts wrong passwords below the limit without locking' do
      user = create(:user)
      fail_logins(user, User::LOGIN_MAX_ATTEMPTS - 1)

      expect(user.reload.failed_login_attempts).to eq(User::LOGIN_MAX_ATTEMPTS - 1)
      expect(user).not_to be_login_locked
      expect(user).to be_can_sign_in
    end

    it 'locks on the limit and emails the unlock link exactly once' do
      user = create(:user)
      fail_logins(user, User::LOGIN_MAX_ATTEMPTS - 1)

      expect { user.register_failed_login! }.to have_enqueued_mail(PasswordsMailer, :unlock).once
      expect(user.reload).to be_login_locked
      expect(user).not_to be_can_sign_in

      # Further failures neither count nor re-send the email.
      expect { fail_logins(user, 3) }.not_to have_enqueued_mail(PasswordsMailer, :unlock)
      expect(user.reload.failed_login_attempts).to eq(User::LOGIN_MAX_ATTEMPTS)
    end

    it 'never counts a banned account, so it never gets an unlock email' do
      user = create(:user, status: :blocked)

      expect { fail_logins(user, User::LOGIN_MAX_ATTEMPTS) }.not_to have_enqueued_mail(PasswordsMailer, :unlock)
      expect(user.reload.failed_login_attempts).to eq(0)
      expect(user).not_to be_login_locked
    end

    it 'reset_failed_logins! clears the counter' do
      user = create(:user)
      fail_logins(user, 3)

      user.reset_failed_logins!

      expect(user.reload.failed_login_attempts).to eq(0)
    end

    it 'a new password lifts the lock and keeps the status (an admin stays admin)' do
      admin = create(:user, status: :admin)
      fail_logins(admin, User::LOGIN_MAX_ATTEMPTS)

      admin.update!(password: 'brand-new-pass1', password_confirmation: 'brand-new-pass1')

      expect(admin.reload).not_to be_login_locked
      expect(admin.failed_login_attempts).to eq(0)
      expect(admin).to be_admin
    end

    it 'a new password never lifts an admin ban' do
      user = create(:user, status: :blocked)

      user.update!(password: 'brand-new-pass1', password_confirmation: 'brand-new-pass1')

      expect(user.reload).to be_blocked
      expect(user).not_to be_can_sign_in
    end
  end

  describe '#followed_playlist?' do
    it 'is true when the user has a PlaylistFollow for the playlist' do
      follower = create(:user)
      owner    = create(:user)
      playlist = create(:playlist, user: owner, status: :public)
      create(:playlist_follow, user: follower, playlist: playlist)

      expect(follower.followed_playlist?(playlist)).to be true
    end

    it 'is false otherwise' do
      follower = create(:user)
      owner    = create(:user)
      playlist = create(:playlist, user: owner, status: :public)

      expect(follower.followed_playlist?(playlist)).to be false
    end
  end

  describe '#followed_playlists' do
    it 'returns the playlists the user follows' do
      follower = create(:user)
      owner    = create(:user)
      one = create(:playlist, user: owner, status: :public)
      two = create(:playlist, user: owner, status: :public, name: 'Other Mix')
      create(:playlist_follow, user: follower, playlist: one)
      create(:playlist_follow, user: follower, playlist: two)

      expect(follower.followed_playlists).to contain_exactly(one, two)
    end
  end
end
