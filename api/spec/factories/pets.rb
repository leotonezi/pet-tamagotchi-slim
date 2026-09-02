FactoryBot.define do
  factory :pet do
    association :user
    sequence(:name) { |n| "Pet#{n}" }
    species { "Cat" }
    hunger { 30 }
    tiredness { 20 }
    hygiene { 80 }
    happiness { 70 }
    health { 75 }
    needs_meal { false }
    needs_walk { false }
    needs_bath { false }
    is_alive { true }
    birth_date { Time.current }
    last_interaction { Time.current }

    trait :dead do
      is_alive { false }
    end

    trait :hungry do
      hunger { 96 }
    end

    trait :needs_care do
      hunger { 75 }
      hygiene { 35 }
      happiness { 50 }
    end
  end
end
