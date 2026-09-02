import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
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

export function usePetAction(id: number) {
  const qc = useQueryClient()
  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ['pet', id] })
    qc.invalidateQueries({ queryKey: ['pets'] })
  }

  const mutation = (fn: () => Promise<{ data: unknown }>) =>
    useMutation({ mutationFn: fn, onSuccess: invalidate })

  return {
    feed:  useMutation({ mutationFn: () => petsApi.feed(id),  onSuccess: invalidate }),
    walk:  useMutation({ mutationFn: () => petsApi.walk(id),  onSuccess: invalidate }),
    bathe: useMutation({ mutationFn: () => petsApi.bathe(id), onSuccess: invalidate }),
    sleep: useMutation({ mutationFn: () => petsApi.sleep(id), onSuccess: invalidate }),
    play:  useMutation({ mutationFn: () => petsApi.play(id),  onSuccess: invalidate }),
    // suppress unused variable warning — mutation factory kept for future use
    _mutation: mutation,
  }
}
