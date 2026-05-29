require 'rails_helper'

RSpec.describe SongPolicy do
  let(:song) { create(:song) }
  let(:regular_user) { create(:user, status: :active) }
  let(:admin_user) { create(:user, status: :admin) }

  describe '#show? and #index?' do
    it 'always allows show and index' do
      [ nil, regular_user, admin_user ].each do |actor|
        policy = described_class.new(actor, song)
        expect(policy.show?).to be(true)
        expect(policy.index?).to be(true)
      end
    end
  end

  describe '#update? / #create? / #destroy?' do
    it 'denies a regular user' do
      policy = described_class.new(regular_user, song)
      expect(policy.update?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.destroy?).to be_falsey
    end

    it 'denies an anonymous user' do
      policy = described_class.new(nil, song)
      expect(policy.update?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.destroy?).to be_falsey
    end

    it 'allows an admin user' do
      policy = described_class.new(admin_user, song)
      expect(policy.update?).to be(true)
      expect(policy.create?).to be(true)
      expect(policy.destroy?).to be(true)
    end
  end
end
