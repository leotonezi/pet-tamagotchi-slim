import client from './client'

export interface RewardStatus {
  eligible: boolean
  next_claim_at: string
  last_claimed_at: string | null
}

export interface ClaimResult {
  coins_awarded: number
  total_coins: number
}

export const rewardsApi = {
  status: () => client.get<RewardStatus>('/api/v1/rewards'),
  claim:  () => client.post<ClaimResult>('/api/v1/rewards/claim'),
}
