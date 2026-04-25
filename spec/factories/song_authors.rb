FactoryBot.define do
  factory :song_author do
    song { association :song }
    author { association :author }
  end
end
