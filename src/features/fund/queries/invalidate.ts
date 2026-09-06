import type { QueryClient } from '@tanstack/react-query'
import { eventKeys } from '@/features/fund/queries/events'
import { dashboardKeys } from '@/features/fund/queries/dashboard'
import { performanceKeys } from '@/features/fund/queries/performance'

export function invalidateFundQueries(queryClient: QueryClient) {
  return Promise.all([
    queryClient.invalidateQueries({ queryKey: eventKeys.all }),
    queryClient.invalidateQueries({ queryKey: dashboardKeys.all }),
    queryClient.invalidateQueries({ queryKey: performanceKeys.all }),
  ])
}
