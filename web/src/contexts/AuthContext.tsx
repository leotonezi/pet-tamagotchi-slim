import { createContext, useCallback, useContext, useEffect, useState } from 'react'
import { authApi, type User } from '../api/auth'

interface AuthContextValue {
  user: User | null
  token: string | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<void>
  signUp: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('jwt'))
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!token) {
      setLoading(false)
      return
    }
    authApi.me()
      .then(res => setUser(res.data))
      .catch(() => {
        localStorage.removeItem('jwt')
        setToken(null)
      })
      .finally(() => setLoading(false))
  }, [token])

  const signIn = useCallback(async (email: string, password: string) => {
    const res = await authApi.signIn(email, password)
    localStorage.setItem('jwt', res.data.token)
    setToken(res.data.token)
    setUser(res.data.user)
  }, [])

  const signUp = useCallback(async (email: string, password: string) => {
    const res = await authApi.signUp(email, password)
    localStorage.setItem('jwt', res.data.token)
    setToken(res.data.token)
    setUser(res.data.user)
  }, [])

  const signOut = useCallback(async () => {
    await authApi.signOut().catch(() => {})
    localStorage.removeItem('jwt')
    setToken(null)
    setUser(null)
  }, [])

  return (
    <AuthContext.Provider value={{ user, token, loading, signIn, signUp, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
