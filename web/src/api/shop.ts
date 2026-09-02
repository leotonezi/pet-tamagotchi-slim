import client from './client'

export interface Item {
  id: number
  name: string
  description: string
  price_coins: number
  hunger_delta: number
  hygiene_delta: number
  happiness_delta: number
  tiredness_delta: number
}

export interface InventorySlot {
  id: number
  qty: number
  item: Item
}

export interface Inventory {
  id: number
  inventory_slots: InventorySlot[]
}

export const shopApi = {
  items: () => client.get<Item[]>('/api/v1/items'),
  inventory: () => client.get<Inventory>('/api/v1/inventory'),
  buy: (item_id: number, qty = 1) =>
    client.post<Inventory>('/api/v1/inventory/buy', { item_id, qty }),
  use: (item_id: number, pet_id: number) =>
    client.post('/api/v1/inventory/use', { item_id, pet_id }),
}
