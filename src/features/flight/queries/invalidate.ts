import type { QueryClient } from '@tanstack/react-query'
import { flightKeys } from '@/features/flight/queries/flights'

export function invalidateFlightQueries(queryClient: QueryClient) {
  return queryClient.invalidateQueries({ queryKey: flightKeys.all })
}
