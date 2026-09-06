import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'

import type { FlightUpsertInput } from '@/features/flight/api.supabase'
import { updateFlight as updateFlightRequest } from '@/features/flight/api.supabase'
import { invalidateFlightQueries } from '@/features/flight/queries/invalidate'

interface UpdateFlightVariables {
  flightId: number
  input: FlightUpsertInput
}

export function useUpdateFlight() {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn: ({ flightId, input }: UpdateFlightVariables) =>
      updateFlightRequest(flightId, input),
    onSuccess: async () => {
      await invalidateFlightQueries(queryClient)
      toast.success('Flight updated successfully')
    },
    onError: (error: Error) => {
      toast.error('Failed to update flight', { description: error.message })
    },
  })

  return {
    updateFlight: (flightId: number, input: FlightUpsertInput) =>
      mutation.mutateAsync({ flightId, input }),
    isPending: mutation.isPending,
  }
}
