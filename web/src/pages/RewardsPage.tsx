import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { rewardsApi } from '../api/rewards'
import { useAuth } from '../contexts/AuthContext'
import { Gift } from 'lucide-react'

export default function RewardsPage() {
  const { user } = useAuth()
  const qc = useQueryClient()
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')

  const { data: status, isLoading } = useQuery({
    queryKey: ['rewards'],
    queryFn: () => rewardsApi.status().then(r => r.data),
    refetchInterval: 60_000,
  })

  const claimMutation = useMutation({
    mutationFn: () => rewardsApi.claim(),
    onSuccess: (res) => {
      qc.invalidateQueries({ queryKey: ['rewards'] })
      qc.invalidateQueries({ queryKey: ['me'] })
      setMessage(`You got ${res.data.coins_awarded} coins! Total: ${res.data.total_coins}`)
      setError('')
    },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error
      setError(msg ?? 'Claim failed')
      setMessage('')
    },
  })

  const [countdown, setCountdown] = useState('')

  useEffect(() => {
    if (!status || status.eligible) { setCountdown(''); return }

    const update = () => {
      const diff = new Date(status.next_claim_at).getTime() - Date.now()
      if (diff <= 0) { setCountdown(''); qc.invalidateQueries({ queryKey: ['rewards'] }); return }
      const h = Math.floor(diff / 3_600_000)
      const m = Math.floor((diff % 3_600_000) / 60_000)
      const s = Math.floor((diff % 60_000) / 1_000)
      setCountdown(`${h}h ${m}m ${s}s`)
    }

    update()
    const id = setInterval(update, 1_000)
    return () => clearInterval(id)
  }, [status, qc])

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-md mx-auto">
        <div className="flex items-center justify-between mb-8">
          <h1 className="text-3xl font-bold">Daily Reward</h1>
          <div className="flex gap-4 text-sm">
            <Link to="/pets" className="text-blue-500 hover:underline">Pets</Link>
            <Link to="/shop" className="text-blue-500 hover:underline">Shop</Link>
          </div>
        </div>

        <div className="bg-white rounded-2xl shadow p-8 text-center">
          <Gift className="w-14 h-14 mx-auto mb-4 text-pink-500" />
          <p className="text-sm text-gray-400 mb-6">
            {user?.coins ?? 0} coins in wallet
          </p>

          {isLoading && <p className="text-gray-400">Loading…</p>}

          {!isLoading && status && (
            <>
              {message && (
                <p className="text-green-600 font-semibold mb-4">{message}</p>
              )}
              {error && (
                <p className="text-red-500 text-sm mb-4">{error}</p>
              )}

              {status.eligible ? (
                <>
                  <p className="text-gray-500 mb-6 text-sm">
                    Claim your daily reward — between 10 and 25 coins.
                  </p>
                  <button
                    onClick={() => claimMutation.mutate()}
                    disabled={claimMutation.isPending}
                    className="bg-yellow-400 hover:bg-yellow-500 text-white font-bold rounded-2xl px-8 py-3 text-lg disabled:opacity-50 transition-colors"
                  >
                    {claimMutation.isPending ? 'Claiming…' : 'Claim Reward'}
                  </button>
                </>
              ) : (
                <>
                  <p className="text-gray-400 text-sm mb-2">Next reward in</p>
                  <p className="text-3xl font-mono font-bold text-gray-700 mb-4">
                    {countdown || '—'}
                  </p>
                  {status.last_claimed_at && (
                    <p className="text-xs text-gray-300">
                      Last claimed {new Date(status.last_claimed_at).toLocaleString()}
                    </p>
                  )}
                </>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  )
}
