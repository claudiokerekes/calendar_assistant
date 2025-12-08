FactoryBot.define do
  factory :schedule do
    title { Faker::Lorem.words(number: 3).join(' ') }
    description { Faker::Lorem.sentence }
    start_time { 1.day.from_now }
    end_time { 2.days.from_now }
    location { Faker::Address.city }
    all_day { false }
    association :calendar
  end
end
