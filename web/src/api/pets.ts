import client from './client'

export interface Pet {
  id: number
  name: string
  species: string
  hunger: number
  tiredness: number
  hygiene: number
  happiness: number
  health: number
  needs_meal: boolean
  needs_walk: boolean
  needs_bath: boolean
  is_alive: boolean
  birth_date: string
  last_interaction: string
}

export const petsApi = {
  list: () => client.get<Pet[]>('/api/v1/pets'),
  get: (id: number) => client.get<Pet>(`/api/v1/pets/${id}`),
  create: (name: string, species: string) =>
    client.post<Pet>('/api/v1/pets', { pet: { name, species } }),
  destroy: (id: number) => client.delete(`/api/v1/pets/${id}`),
  feed: (id: number) => client.post<Pet>(`/api/v1/pets/${id}/feed`),
  walk: (id: number) => client.post<Pet>(`/api/v1/pets/${id}/walk`),
  bathe: (id: number) => client.post<Pet>(`/api/v1/pets/${id}/bathe`),
  sleep: (id: number) => client.post<Pet>(`/api/v1/pets/${id}/sleep`),
  play: (id: number) => client.post<Pet>(`/api/v1/pets/${id}/play`),
  checkStatus: (id: number) => client.post<Pet>(`/api/v1/pets/${id}/check_status`),
}
