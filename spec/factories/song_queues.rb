FactoryBot.define do
  factory :song_queue do
    user { association :user }
    song { association :song }
    source { FFaker::Internet.http_url }
  end
end
