FactoryBot.define do
  factory :author do
    name { FFaker::Music.unique.artist }
    description { FFaker::Lorem.paragraph }
    user { association :user }
  end
end
