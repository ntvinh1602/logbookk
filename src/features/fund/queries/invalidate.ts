import type { QueryClient } from '@tanstack/react-query'
import { eventKeys } from './events'
import { dashboardKeys } from './dashboard'
import { performanceKeys } from './performance'

export function invalidateFundQueries(queryClient: QueryClient) {
  return Promise.all([
    queryClient.invalidateQueries({ queryKey: eventKeys.all }),
    queryClient.invalidateQueries({ queryKey: dashboardKeys.all }),
    queryClient.invalidateQueries({ queryKey: performanceKeys.all }),
  ])
}
