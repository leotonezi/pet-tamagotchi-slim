import { useQuery, useQueryClient } from '@tanstack/react-query'
import { petsApi } from '../api/pets'

export function usePets() {
  return useQuery({
    queryKey: ['pets'],
    queryFn: () => petsApi.list().then(r => r.data),
    refetchInterval: 60_000,
  })
}

export function usePet(id: number) {
  return useQuery({
    queryKey: ['pet', id],
    queryFn: () => petsApi.get(id).then(r => r.data),
    // poll every 5s while action active, every 60s idle
    refetchInterval: (query) => {
      const pet = query.state.data
      if (!pet) return false
      const busy = pet.active_action && pet.action_ends_at && new Date(pet.action_ends_at) > new Date()
      return busy ? 5_000 : 60_000
    },
  })
}

export function useInvalidatePet(id: number) {
  const qc = useQueryClient()
  return () => {
    qc.invalidateQueries({ queryKey: ['pet', id] })
    qc.invalidateQueries({ queryKey: ['pets'] })
  }
}
