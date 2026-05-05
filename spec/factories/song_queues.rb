FactoryBot.define do
  factory :song_queue do
    user { association :user }
    song { association :song }
    source { SongQueue::SOURCES.sample }
  end
end
