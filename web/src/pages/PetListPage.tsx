import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { petsApi } from '../api/pets'
import { useAuth } from '../contexts/AuthContext'
import { usePets } from '../hooks/usePet'
import { Gift, ShoppingCart } from 'lucide-react'
import PetAvatar from '../components/pet/PetAvatar'

export default function PetListPage() {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()
  const qc = useQueryClient()
  const { data: pets, isLoading } = usePets()

  const [name, setName] = useState('')
  const [species, setSpecies] = useState('')
  const [formError, setFormError] = useState('')

  const [breedOpen, setBreedOpen] = useState(false)
  const [breedParentA, setBreedParentA] = useState('')
  const [breedParentB, setBreedParentB] = useState('')
  const [breedName, setBreedName] = useState('')
  const [breedError, setBreedError] = useState('')
  const [breedSuccess, setBreedSuccess] = useState('')

  const createMutation = useMutation({
    mutationFn: () => petsApi.create(name, species),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['pets'] })
      setName('')
      setSpecies('')
      setFormError('')
    },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error
      setFormError(msg ?? 'Failed to create pet')
    },
  })

  const breedMutation = useMutation({
    mutationFn: () =>
      petsApi.breed(Number(breedParentA), Number(breedParentB), breedName),
    onSuccess: (res) => {
      qc.invalidateQueries({ queryKey: ['pets'] })
      setBreedError('')
      setBreedSuccess(`${res.data.name} (${res.data.species}) was born!`)
      setBreedParentA('')
      setBreedParentB('')
      setBreedName('')
    },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error
      setBreedError(msg ?? 'Breeding failed')
      setBreedSuccess('')
    },
  })

  async function handleSignOut() {
    await signOut()
    navigate('/login')
  }

  const alivePets = pets?.filter(p => p.is_alive) ?? []

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold">My Pets</h1>
            <p className="text-sm text-gray-500 mt-1">{user?.email} · {user?.coins ?? 0} coins</p>
          </div>
          <div className="flex items-center gap-4">
            <Link to="/shop" className="inline-flex items-center gap-1 text-sm text-blue-500 hover:underline"><ShoppingCart className="w-4 h-4" /> Shop</Link>
            <Link to="/rewards" className="inline-flex items-center gap-1 text-sm text-blue-500 hover:underline"><Gift className="w-4 h-4" /> Rewards</Link>
            <button onClick={handleSignOut} className="text-sm text-gray-500 hover:text-red-500">
              Sign out
            </button>
          </div>
        </div>

        {/* Create form */}
        <div className="bg-white rounded-2xl shadow p-6 mb-6">
          <h2 className="font-semibold mb-4">New Pet</h2>
          {formError && <p className="text-red-600 text-sm mb-3">{formError}</p>}
          <div className="flex gap-3">
            <input
              placeholder="Name"
              value={name}
              onChange={e => setName(e.target.value)}
              maxLength={32}
              className="flex-1 border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
            />
            <input
              placeholder="Species"
              value={species}
              onChange={e => setSpecies(e.target.value)}
              maxLength={16}
              className="w-32 border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
            />
            <button
              onClick={() => createMutation.mutate()}
              disabled={!name || !species || createMutation.isPending}
              className="bg-blue-500 text-white rounded-lg px-4 py-2 text-sm font-semibold hover:bg-blue-600 disabled:opacity-50"
            >
              {createMutation.isPending ? '…' : 'Create'}
            </button>
          </div>
        </div>

        {/* Breed section */}
        {alivePets.length >= 2 && (
          <div className="bg-white rounded-2xl shadow p-6 mb-6">
            <button
              onClick={() => { setBreedOpen(o => !o); setBreedError(''); setBreedSuccess('') }}
              className="w-full flex items-center justify-between font-semibold"
            >
              <span>Breed Pets</span>
              <span className="text-gray-400 text-sm">{breedOpen ? '▲' : '▼'}</span>
            </button>

            {breedOpen && (
              <div className="mt-4 space-y-3">
                {breedError && <p className="text-red-600 text-sm">{breedError}</p>}
                {breedSuccess && <p className="text-green-600 text-sm">{breedSuccess}</p>}

                <div className="flex gap-3">
                  <select
                    value={breedParentA}
                    onChange={e => setBreedParentA(e.target.value)}
                    className="flex-1 border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-pink-400"
                  >
                    <option value="">Parent A</option>
                    {alivePets.map(p => (
                      <option key={p.id} value={p.id} disabled={String(p.id) === breedParentB}>
                        {p.name} ({p.species})
                      </option>
                    ))}
                  </select>

                  <select
                    value={breedParentB}
                    onChange={e => setBreedParentB(e.target.value)}
                    className="flex-1 border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-pink-400"
                  >
                    <option value="">Parent B</option>
                    {alivePets.map(p => (
                      <option key={p.id} value={p.id} disabled={String(p.id) === breedParentA}>
                        {p.name} ({p.species})
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex gap-3">
                  <input
                    placeholder="Offspring name"
                    value={breedName}
                    onChange={e => setBreedName(e.target.value)}
                    maxLength={32}
                    className="flex-1 border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-pink-400"
                  />
                  <button
                    onClick={() => breedMutation.mutate()}
                    disabled={!breedParentA || !breedParentB || !breedName || breedMutation.isPending}
                    className="bg-pink-500 text-white rounded-lg px-4 py-2 text-sm font-semibold hover:bg-pink-600 disabled:opacity-50"
                  >
                    {breedMutation.isPending ? '…' : 'Breed'}
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Pet list */}
        {isLoading && <p className="text-gray-400 text-center">Loading…</p>}
        {pets?.length === 0 && (
          <p className="text-gray-400 text-center py-12">No pets yet. Create one above.</p>
        )}
        <div className="space-y-3">
          {pets?.map(pet => (
            <Link
              key={pet.id}
              to={`/pets/${pet.id}`}
              className="block bg-white rounded-2xl shadow p-5 hover:shadow-md transition-shadow"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center">
                  <PetAvatar species={pet.species} className={`w-5 h-5 mr-2 ${pet.is_alive ? 'text-gray-700' : 'text-gray-300'}`} />
                  <span className="font-semibold">{pet.name}</span>
                  <span className="ml-2 text-sm text-gray-400">{pet.species}</span>
                  {!pet.is_alive && (
                    <span className="ml-2 text-xs text-red-500 font-medium">DEAD</span>
                  )}
                </div>
                <div className="flex gap-2 text-xs text-gray-500">
                  {pet.needs_meal && <span className="bg-orange-100 text-orange-600 px-2 py-0.5 rounded-full">hungry</span>}
                  {pet.needs_bath && <span className="bg-yellow-100 text-yellow-600 px-2 py-0.5 rounded-full">dirty</span>}
                  {pet.needs_walk && <span className="bg-blue-100 text-blue-600 px-2 py-0.5 rounded-full">bored</span>}
                </div>
              </div>
              <div className="mt-3">
                <StatBar label="Health" value={pet.health} color="bg-green-400" />
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  )
}

function StatBar({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div className="flex items-center gap-2">
      <span className="text-xs text-gray-400 w-12">{label}</span>
      <div className="flex-1 h-2 bg-gray-100 rounded-full overflow-hidden">
        <div className={`h-full ${color} rounded-full`} style={{ width: `${value}%` }} />
      </div>
      <span className="text-xs text-gray-400 w-6 text-right">{value}</span>
    </div>
  )
}
