FactoryBot.define do
  factory :session do
    user { association :user }
    ip_address { FFaker::Internet.ip_v4_address }
    user_agent { FFaker::Internet.user_agent }
  end
end
