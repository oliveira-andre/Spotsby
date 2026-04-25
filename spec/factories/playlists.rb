FactoryBot.define do
  factory :playlist do
    name { "#{FFaker::Music.unique.genre} #{FFaker::Lorem.unique.word.capitalize} Mix" }
    status { :private }
    user { association :user }
  end
end
