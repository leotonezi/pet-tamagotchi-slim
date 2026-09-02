import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { petsApi } from '../api/pets'
import { shopApi } from '../api/shop'
import { usePet } from '../hooks/usePet'

const ACTION_LABELS: Record<string, string> = {
  feeding:  '🍖 Feeding',
  walking:  '🦮 Walking',
  bathing:  '🛁 Bathing',
  sleeping: '💤 Sleeping',
  playing:  '🎮 Playing',
}

function useCountdown(endsAt: string | null) {
  const [remaining, setRemaining] = useState('')

  useEffect(() => {
    if (!endsAt) { setRemaining(''); return }
    const update = () => {
      const diff = new Date(endsAt).getTime() - Date.now()
      if (diff <= 0) { setRemaining(''); return }
      const h = Math.floor(diff / 3600000)
      const m = Math.floor((diff % 3600000) / 60000)
      const s = Math.floor((diff % 60000) / 1000)
      setRemaining(h > 0 ? `${h}h ${m}m` : m > 0 ? `${m}m ${s}s` : `${s}s`)
    }
    update()
    const id = setInterval(update, 1000)
    return () => clearInterval(id)
  }, [endsAt])

  return remaining
}

export default function PetDetailPage() {
  const { id } = useParams<{ id: string }>()
  const petId = Number(id)
  const qc = useQueryClient()
  const { data: pet, isLoading } = usePet(petId)

  const [sleepPicker, setSleepPicker] = useState(false)
  const [playPicker, setPlayPicker]   = useState(false)

  const countdown = useCountdown(pet?.action_ends_at ?? null)

  const { data: inventory } = useQuery({
    queryKey: ['inventory'],
    queryFn: () => shopApi.inventory().then(r => r.data),
  })

  const invalidate = () => qc.invalidateQueries({ queryKey: ['pet', petId] })

  const useMut = useMutation({
    mutationFn: (itemId: number) => shopApi.use(itemId, petId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['pet', petId] })
      qc.invalidateQueries({ queryKey: ['inventory'] })
    },
  })

  const feedMut  = useMutation({ mutationFn: () => petsApi.feed(petId),  onSuccess: invalidate })
  const walkMut  = useMutation({ mutationFn: () => petsApi.walk(petId),  onSuccess: invalidate })
  const batheMut = useMutation({ mutationFn: () => petsApi.bathe(petId), onSuccess: invalidate })
  const sleepMut = useMutation({ mutationFn: (h: 4 | 8)    => petsApi.sleep(petId, h), onSuccess: () => { setSleepPicker(false); invalidate() } })
  const playMut  = useMutation({ mutationFn: (h: 1 | 2 | 4) => petsApi.play(petId, h), onSuccess: () => { setPlayPicker(false);  invalidate() } })

  if (isLoading) return <div className="p-8 text-gray-400">Loading…</div>
  if (!pet)      return <div className="p-8 text-red-500">Pet not found.</div>

  const dead   = !pet.is_alive
  const busy   = !!(pet.active_action && pet.action_ends_at && new Date(pet.action_ends_at) > new Date())
  const anyLoading = [feedMut, walkMut, batheMut, sleepMut, playMut].some(m => m.isPending)

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-lg mx-auto">
        <Link to="/pets" className="text-sm text-blue-500 hover:underline mb-6 block">← All pets</Link>

        <div className="bg-white rounded-2xl shadow p-6">
          {/* Header */}
          <div className="flex items-center justify-between mb-1">
            <h1 className="text-2xl font-bold">{pet.name}</h1>
            {dead
              ? <span className="text-red-500 font-semibold text-sm">DEAD</span>
              : <span className="text-green-500 font-semibold text-sm">Alive</span>}
          </div>
          <p className="text-gray-400 text-sm mb-4">{pet.species}</p>

          {/* Active action banner */}
          {busy && (
            <div className="mb-5 flex items-center justify-between bg-blue-50 border border-blue-200 rounded-xl px-4 py-3">
              <span className="text-blue-700 font-medium text-sm">
                {ACTION_LABELS[pet.active_action!] ?? pet.active_action}…
              </span>
              {countdown && (
                <span className="text-blue-400 text-xs tabular-nums">{countdown}</span>
              )}
            </div>
          )}

          {/* Need badges */}
          {!busy && (
            <div className="flex gap-2 mb-5 flex-wrap">
              {pet.needs_meal && <Badge color="orange">🍖 Hungry</Badge>}
              {pet.needs_bath && <Badge color="yellow">🛁 Dirty</Badge>}
              {pet.needs_walk && <Badge color="blue">🦮 Bored</Badge>}
              {!pet.needs_meal && !pet.needs_bath && !pet.needs_walk && !dead && (
                <span className="text-xs text-gray-400">All good!</span>
              )}
            </div>
          )}

          {/* Stats */}
          <div className="space-y-3 mb-8">
            <StatBar label="Health"    value={pet.health}    color="bg-green-400" />
            <StatBar label="Hunger"    value={pet.hunger}    color="bg-orange-400" invert />
            <StatBar label="Tiredness" value={pet.tiredness} color="bg-purple-400" invert />
            <StatBar label="Hygiene"   value={pet.hygiene}   color="bg-cyan-400" />
            <StatBar label="Happiness" value={pet.happiness} color="bg-yellow-400" />
          </div>

          {/* Care buttons */}
          {!dead && (
            <div className="grid grid-cols-2 gap-3">
              <ActionBtn label="🍖 Feed"  onClick={() => feedMut.mutate()}  disabled={busy || anyLoading} loading={feedMut.isPending} />
              <ActionBtn label="🦮 Walk"  onClick={() => walkMut.mutate()}  disabled={busy || anyLoading} loading={walkMut.isPending} />
              <ActionBtn label="🛁 Bathe" onClick={() => batheMut.mutate()} disabled={busy || anyLoading} loading={batheMut.isPending} />

              {/* Sleep picker */}
              <div className="relative">
                <ActionBtn
                  label="💤 Sleep"
                  onClick={() => { setSleepPicker(v => !v); setPlayPicker(false) }}
                  disabled={busy || anyLoading}
                  loading={sleepMut.isPending}
                />
                {sleepPicker && (
                  <div className="absolute bottom-full left-0 mb-2 bg-white border rounded-xl shadow-lg p-3 z-10 w-full">
                    <p className="text-xs text-gray-500 mb-2">Duration</p>
                    <div className="flex gap-2">
                      {([4, 8] as const).map(h => (
                        <button
                          key={h}
                          onClick={() => sleepMut.mutate(h)}
                          className="flex-1 py-1.5 text-sm rounded-lg bg-purple-50 hover:bg-purple-100 text-purple-700 font-medium"
                        >
                          {h}h
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Play picker */}
              <div className="relative">
                <ActionBtn
                  label="🎮 Play"
                  onClick={() => { setPlayPicker(v => !v); setSleepPicker(false) }}
                  disabled={busy || anyLoading}
                  loading={playMut.isPending}
                />
                {playPicker && (
                  <div className="absolute bottom-full left-0 mb-2 bg-white border rounded-xl shadow-lg p-3 z-10 w-full">
                    <p className="text-xs text-gray-500 mb-2">Duration</p>
                    <div className="flex gap-2">
                      {([1, 2, 4] as const).map(h => (
                        <button
                          key={h}
                          onClick={() => playMut.mutate(h)}
                          className="flex-1 py-1.5 text-sm rounded-lg bg-yellow-50 hover:bg-yellow-100 text-yellow-700 font-medium"
                        >
                          {h}h
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}

          {dead && (
            <p className="text-center text-gray-400 text-sm mt-4">
              This pet has passed away.
            </p>
          )}
        </div>

        {/* Inventory panel */}
        {(() => {
          const ownedSlots = inventory?.inventory_slots.filter(s => s.qty > 0) ?? []
          if (ownedSlots.length === 0) return null
          return (
            <div className="bg-white rounded-2xl shadow p-6 mt-4">
              <h2 className="font-semibold mb-4 text-sm text-gray-500 uppercase tracking-wide">Inventory</h2>
              <div className="grid grid-cols-2 gap-3">
                {ownedSlots.map(slot => (
                  <div key={slot.id} className="border rounded-xl p-3 flex items-center justify-between gap-2">
                    <div className="min-w-0">
                      <p className="font-medium text-sm truncate">{slot.item.name}</p>
                      <p className="text-xs text-gray-400">×{slot.qty}</p>
                    </div>
                    <button
                      onClick={() => useMut.mutate(slot.item.id)}
                      disabled={dead || useMut.isPending}
                      className="shrink-0 text-xs bg-green-500 text-white rounded-lg px-3 py-1.5 font-semibold hover:bg-green-600 disabled:opacity-40"
                    >
                      Use
                    </button>
                  </div>
                ))}
              </div>
              <Link to="/shop" className="block mt-4 text-xs text-center text-blue-500 hover:underline">
                Shop for more →
              </Link>
            </div>
          )
        })()}
      </div>
    </div>
  )
}

function StatBar({ label, value, color, invert = false }: {
  label: string; value: number; color: string; invert?: boolean
}) {
  const display = invert ? 100 - value : value
  return (
    <div className="flex items-center gap-3">
      <span className="text-xs text-gray-500 w-20">{label}</span>
      <div className="flex-1 h-2.5 bg-gray-100 rounded-full overflow-hidden">
        <div className={`h-full ${color} rounded-full transition-all duration-500`} style={{ width: `${display}%` }} />
      </div>
      <span className="text-xs text-gray-400 w-6 text-right">{value}</span>
    </div>
  )
}

function Badge({ children, color }: { children: React.ReactNode; color: string }) {
  const map: Record<string, string> = {
    orange: 'bg-orange-100 text-orange-600',
    yellow: 'bg-yellow-100 text-yellow-600',
    blue:   'bg-blue-100 text-blue-600',
  }
  return <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${map[color] ?? ''}`}>{children}</span>
}

function ActionBtn({ label, onClick, disabled, loading }: {
  label: string; onClick: () => void; disabled: boolean; loading: boolean
}) {
  return (
    <button
      onClick={onClick}
      disabled={disabled || loading}
      className="w-full py-2 rounded-xl border border-gray-200 text-sm font-medium hover:bg-gray-50 disabled:opacity-40 transition-colors"
    >
      {loading ? '…' : label}
    </button>
  )
}
