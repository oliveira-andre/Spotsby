FactoryBot.define do
  factory :author do
    sequence :name do |n|
      "#{FFaker::Music.artist} #{n}"
    end
    description { FFaker::Lorem.paragraph }
    user { association :user }
  end
end
