import type { QueryClient } from '@tanstack/react-query'
import { flightKeys } from './flights'

export function invalidateFlightQueries(queryClient: QueryClient) {
  return queryClient.invalidateQueries({ queryKey: flightKeys.all })
}
