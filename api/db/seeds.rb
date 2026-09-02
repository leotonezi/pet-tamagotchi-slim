items = [
  { name: "Apple",  description: "A fresh apple. Fills your pet right up.",      price_coins: 10, hunger_delta: -30, hygiene_delta: 0,   happiness_delta: 5,  tiredness_delta: 0   },
  { name: "Soap",   description: "Squeaky clean. Way more thorough than a bath.", price_coins: 10, hunger_delta: 0,   hygiene_delta: 60,  happiness_delta: 0,  tiredness_delta: 0   },
  { name: "Toy",    description: "Instant fun. Wears them out a little.",         price_coins: 10, hunger_delta: 0,   hygiene_delta: 0,   happiness_delta: 30, tiredness_delta: 10  },
  { name: "Pillow", description: "Deep sleep in a pocket-sized package.",         price_coins: 10, hunger_delta: 5,   hygiene_delta: 0,   happiness_delta: 0,  tiredness_delta: -60 }
]

items.each do |attrs|
  Item.find_or_create_by!(name: attrs[:name]) do |i|
    i.assign_attributes(attrs)
  end
end

puts "Seeded #{Item.count} items."
