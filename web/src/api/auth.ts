import client from './client'

export interface User {
  id: number
  email: string
  coins: number
  created_at: string
}

export interface AuthResponse {
  token: string
  user: User
}

export const authApi = {
  signUp: (email: string, password: string) =>
    client.post<AuthResponse>('/api/v1/auth/sign_up', { user: { email, password } }),

  signIn: (email: string, password: string) =>
    client.post<AuthResponse>('/api/v1/auth/sign_in', { user: { email, password } }),

  signOut: () =>
    client.delete('/api/v1/auth/sign_out'),

  me: () =>
    client.get<User>('/api/v1/auth/me'),
}
