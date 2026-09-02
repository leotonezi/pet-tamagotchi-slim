import { useQuery, useQueryClient } from '@tanstack/react-query'
import { petsApi } from '../api/pets'

export function usePets() {
  return useQuery({
    queryKey: ['pets'],
    queryFn: () => petsApi.list().then(r => r.data),
  })
}

export function usePet(id: number) {
  return useQuery({
    queryKey: ['pet', id],
    queryFn: () => petsApi.get(id).then(r => r.data),
  })
}

export function useInvalidatePet(id: number) {
  const qc = useQueryClient()
  return () => {
    qc.invalidateQueries({ queryKey: ['pet', id] })
    qc.invalidateQueries({ queryKey: ['pets'] })
  }
}
