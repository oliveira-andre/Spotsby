FactoryBot.define do
  factory :album do
    sequence :name do |n|
      "#{FFaker::Music.album} #{n}"
    end
    release_date { FFaker::Time.between(Date.new(1970, 1, 1), Date.today) }
    category { association :category }
    author { association :author }
  end
end
