import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { type Item, shopApi } from '../api/shop'
import { useAuth } from '../contexts/AuthContext'

const DELTA_LABELS: Array<{ key: keyof Item; label: string; good: boolean }> = [
  { key: 'hunger_delta',    label: 'Hunger',    good: false },
  { key: 'hygiene_delta',   label: 'Hygiene',   good: true  },
  { key: 'happiness_delta', label: 'Happiness', good: true  },
  { key: 'tiredness_delta', label: 'Tiredness', good: false },
]

export default function ShopPage() {
  const { user } = useAuth()
  const qc = useQueryClient()

  const { data: items, isLoading } = useQuery({
    queryKey: ['items'],
    queryFn: () => shopApi.items().then(r => r.data),
  })

  const { data: inventory } = useQuery({
    queryKey: ['inventory'],
    queryFn: () => shopApi.inventory().then(r => r.data),
  })

  const buyMut = useMutation({
    mutationFn: (itemId: number) => shopApi.buy(itemId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['inventory'] })
      qc.invalidateQueries({ queryKey: ['me'] })
    },
  })

  const slotQty = (itemId: number) =>
    inventory?.inventory_slots.find(s => s.item.id === itemId)?.qty ?? 0

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold">Shop</h1>
            <p className="text-sm text-gray-500 mt-1">💰 {user?.coins ?? 0} coins</p>
          </div>
          <Link to="/pets" className="text-sm text-blue-500 hover:underline">← My Pets</Link>
        </div>

        {isLoading && <p className="text-gray-400 text-center">Loading…</p>}

        <div className="grid gap-4">
          {items?.map(item => (
            <div key={item.id} className="bg-white rounded-2xl shadow p-5 flex items-center gap-4">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-semibold">{item.name}</span>
                  <span className="text-xs text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">
                    {item.price_coins} coins
                  </span>
                  {slotQty(item.id) > 0 && (
                    <span className="text-xs text-green-600 bg-green-50 px-2 py-0.5 rounded-full">
                      ×{slotQty(item.id)} owned
                    </span>
                  )}
                </div>
                <p className="text-sm text-gray-500 mb-2">{item.description}</p>
                <div className="flex gap-3 flex-wrap">
                  {DELTA_LABELS.map(({ key, label, good }) => {
                    const val = item[key] as number
                    if (val === 0) return null
                    const positive = val > 0
                    const beneficial = good ? positive : !positive
                    return (
                      <span
                        key={key}
                        className={`text-xs font-medium ${beneficial ? 'text-green-600' : 'text-red-500'}`}
                      >
                        {positive ? '+' : ''}{val} {label}
                      </span>
                    )
                  })}
                </div>
              </div>
              <button
                onClick={() => buyMut.mutate(item.id)}
                disabled={buyMut.isPending || (user?.coins ?? 0) < item.price_coins}
                className="shrink-0 bg-blue-500 text-white rounded-xl px-4 py-2 text-sm font-semibold hover:bg-blue-600 disabled:opacity-40"
              >
                {buyMut.isPending ? '…' : 'Buy'}
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
