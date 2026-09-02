module ShopService
  Result = Struct.new(:success?, :error, keyword_init: true)

  def self.buy(user:, item:, qty: 1)
    total = item.price_coins * qty
    unless user.coins >= total
      return Result.new(success?: false, error: "Not enough coins (need #{total}, have #{user.coins})")
    end

    ActiveRecord::Base.transaction do
      user.decrement!(:coins, total)
      slot = user.inventory.inventory_slots.find_or_initialize_by(item: item)
      slot.qty = slot.qty.to_i + qty
      slot.save!
    end
    Result.new(success?: true)
  rescue => e
    Result.new(success?: false, error: e.message)
  end

  def self.use(user:, item:, pet:)
    slot = user.inventory.inventory_slots.find_by(item: item)
    unless slot&.qty.to_i > 0
      return Result.new(success?: false, error: "#{item.name} not in inventory")
    end

    ActiveRecord::Base.transaction do
      pet_result = PetMechanics.use_item(pet, item)
      raise pet_result.error unless pet_result.success?

      slot.decrement!(:qty)
    end
    Result.new(success?: true)
  rescue => e
    Result.new(success?: false, error: e.message)
  end
end
