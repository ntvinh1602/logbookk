import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'

import { addFlight as addFlightRequest } from '@/lib/supabase/api/flight.supabase'
import { invalidateFlightQueries } from '../queries/invalidate'

export function useAddFlight() {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn: addFlightRequest,
    onSuccess: async () => {
      await invalidateFlightQueries(queryClient)
      toast.success('Flight added successfully')
    },
    onError: (error: Error) => {
      toast.error('Failed to add flight', { description: error.message })
    },
  })

  return {
    addFlight: mutation.mutateAsync,
    isPending: mutation.isPending,
  }
}
