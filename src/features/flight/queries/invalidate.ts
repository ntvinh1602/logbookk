import type { QueryClient } from '@tanstack/react-query'
import { flightDwdKeys } from '@/features/flight/queries/flights'

export function invalidateFlightQueries(queryClient: QueryClient) {
  return queryClient.invalidateQueries({ queryKey: flightDwdKeys.all })
}
