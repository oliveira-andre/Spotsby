FactoryBot.define do
  factory :playlist_follow do
    user     { association :user }
    playlist { association :playlist }
  end
end
