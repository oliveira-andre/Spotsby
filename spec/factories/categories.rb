FactoryBot.define do
  factory :category do
    name { FFaker::Music.unique.genre }
  end
end
