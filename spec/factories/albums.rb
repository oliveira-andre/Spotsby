FactoryBot.define do
  factory :album do
    name { FFaker::Music.unique.album }
    release_date { FFaker::Time.between(Date.new(1970, 1, 1), Date.today) }
    category { association :category }
    author { association :author }
  end
end
