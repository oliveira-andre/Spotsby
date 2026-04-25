FactoryBot.define do
  factory :playlist do
    name { "#{FFaker::Music.genre} #{FFaker::Lorem.word.capitalize} Mix" }
    status { :private }
    user { association :user }
  end
end
