FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "Item#{n}" }
    description { "A test item." }
    price_coins { 10 }
    hunger_delta { 0 }
    hygiene_delta { 0 }
    happiness_delta { 0 }
    tiredness_delta { 0 }
  end
end
