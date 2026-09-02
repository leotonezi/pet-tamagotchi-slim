import { useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

export default function HomePage() {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()

  async function handleSignOut() {
    await signOut()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <h1 className="text-3xl font-bold">Pet Tamagotchi</h1>
          <button
            onClick={handleSignOut}
            className="text-sm text-gray-500 hover:text-red-500"
          >
            Sign out
          </button>
        </div>
        <div className="bg-white rounded-2xl shadow p-6">
          <p className="text-gray-600">
            Welcome, <span className="font-semibold">{user?.email}</span>
          </p>
          <p className="mt-1 text-gray-500 text-sm">Coins: {user?.coins ?? 0}</p>
          <p className="mt-6 text-gray-400 text-sm">Pets coming in Phase 3.</p>
        </div>
      </div>
    </div>
  )
}
