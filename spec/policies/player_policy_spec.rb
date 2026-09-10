require 'rails_helper'

RSpec.describe PlayerPolicy do
  let(:user) { create(:user) }
  let(:blocked) { create(:user, status: :blocked) }

  %i[show? next? previous? toggle_random?].each do |action|
    describe "##{action}" do
      it 'allows a signed-in user' do
        expect(described_class.new(user, :player).public_send(action)).to be(true)
      end

      it 'denies a blocked user' do
        expect(described_class.new(blocked, :player).public_send(action)).to be(false)
      end

      it 'denies a guest' do
        expect(described_class.new(nil, :player).public_send(action)).to be(false)
      end
    end
  end
end
