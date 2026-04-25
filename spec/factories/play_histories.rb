FactoryBot.define do
  factory :play_history do
    user { association :user }
    song { association :song }
    played_at { FFaker::Time.between(1.year.ago, Time.current) }
  end
end
