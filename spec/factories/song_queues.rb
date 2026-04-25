FactoryBot.define do
  factory :song_queue do
    user { association :user }
    song { association :song }
    source { %w[search user_defined recommendation].sample }
  end
end
