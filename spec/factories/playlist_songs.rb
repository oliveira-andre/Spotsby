FactoryBot.define do
  factory :playlist_song do
    playlist { association :playlist }
    song { association :song }
    added_at { FFaker::Time.between(1.year.ago, Time.current) }
  end
end
