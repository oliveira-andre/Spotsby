FactoryBot.define do
  factory :session do
    user { association :user }
    ip_address { FFaker::Internet.ip_v4_address }
    user_agent { 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' }
  end
end
