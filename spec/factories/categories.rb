FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "#{FFaker::Music.genre} #{n}" }
  end
end
