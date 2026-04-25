FactoryBot.define do
  factory :song do
    name { FFaker::Music.unique.song }
    lyrics { FFaker::Lorem.paragraphs(3).join("\n\n") }
    duartion_ms { FFaker::Random.rand(60_000..420_000) }
    age { FFaker::Random.rand(0..18) }
    category { association :category }
    album { association :album }
  end
end
