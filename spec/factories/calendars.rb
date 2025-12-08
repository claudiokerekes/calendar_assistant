FactoryBot.define do
  factory :calendar do
    name { Faker::Lorem.words(number: 2).join(' ') }
    description { Faker::Lorem.sentence }
    timezone { 'UTC' }
    color { Faker::Color.hex_color }
    association :user
  end
end
