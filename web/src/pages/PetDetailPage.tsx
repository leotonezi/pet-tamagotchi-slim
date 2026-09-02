import { Link, useParams } from 'react-router-dom'
import { usePet, usePetAction } from '../hooks/usePet'

export default function PetDetailPage() {
  const { id } = useParams<{ id: string }>()
  const petId = Number(id)
  const { data: pet, isLoading } = usePet(petId)
  const actions = usePetAction(petId)

  if (isLoading) return <div className="p-8 text-gray-400">Loading…</div>
  if (!pet) return <div className="p-8 text-red-500">Pet not found.</div>

  const dead = !pet.is_alive
  const anyLoading = Object.values(actions).some(
    a => a && typeof a === 'object' && 'isPending' in a && a.isPending
  )

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-lg mx-auto">
        <Link to="/pets" className="text-sm text-blue-500 hover:underline mb-6 block">
          ← All pets
        </Link>

        <div className="bg-white rounded-2xl shadow p-6">
          <div className="flex items-center justify-between mb-1">
            <h1 className="text-2xl font-bold">{pet.name}</h1>
            {dead
              ? <span className="text-red-500 font-semibold text-sm">DEAD</span>
              : <span className="text-green-500 font-semibold text-sm">Alive</span>
            }
          </div>
          <p className="text-gray-400 text-sm mb-6">{pet.species}</p>

          {/* Need badges */}
          <div className="flex gap-2 mb-6 flex-wrap">
            {pet.needs_meal && <Badge color="orange">🍖 Hungry</Badge>}
            {pet.needs_bath && <Badge color="yellow">🛁 Dirty</Badge>}
            {pet.needs_walk && <Badge color="blue">🦮 Bored</Badge>}
            {!pet.needs_meal && !pet.needs_bath && !pet.needs_walk && !dead && (
              <span className="text-xs text-gray-400">All good!</span>
            )}
          </div>

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
              <ActionBtn label="🍖 Feed"  onClick={() => actions.feed.mutate()}  loading={actions.feed.isPending  || anyLoading} />
              <ActionBtn label="🦮 Walk"  onClick={() => actions.walk.mutate()}  loading={actions.walk.isPending  || anyLoading} />
              <ActionBtn label="🛁 Bathe" onClick={() => actions.bathe.mutate()} loading={actions.bathe.isPending || anyLoading} />
              <ActionBtn label="💤 Sleep" onClick={() => actions.sleep.mutate()} loading={actions.sleep.isPending || anyLoading} />
              <ActionBtn label="🎮 Play"  onClick={() => actions.play.mutate()}  loading={actions.play.isPending  || anyLoading} className="col-span-2" />
            </div>
          )}

          {dead && (
            <p className="text-center text-gray-400 text-sm mt-4">
              This pet has passed away. Create a new one.
            </p>
          )}
        </div>
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
        <div className={`h-full ${color} rounded-full transition-all`} style={{ width: `${display}%` }} />
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
  return (
    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${map[color] ?? ''}`}>
      {children}
    </span>
  )
}

function ActionBtn({ label, onClick, loading, className = '' }: {
  label: string; onClick: () => void; loading: boolean; className?: string
}) {
  return (
    <button
      onClick={onClick}
      disabled={loading}
      className={`py-2 rounded-xl border border-gray-200 text-sm font-medium hover:bg-gray-50 disabled:opacity-40 transition-colors ${className}`}
    >
      {loading ? '…' : label}
    </button>
  )
}
