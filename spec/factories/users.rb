FactoryBot.define do
  factory :user do
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    status { :active }
    birthdate { FFaker::Time.between(Date.new(1950, 1, 1), Date.new(2005, 12, 31)) }
    email_address { FFaker::Internet.unique.email }
    password { FFaker::Internet.password(10) }
  end
end
