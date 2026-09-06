import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'

import { deleteFlight } from '@/features/flight/api.supabase'
import { invalidateFlightQueries } from '@/features/flight/queries/invalidate'

export function useDeleteFlight() {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn: deleteFlight,
    onSuccess: async () => {
      await invalidateFlightQueries(queryClient)
      toast.success('Flight deleted successfully')
    },
    onError: (error: Error) => {
      toast.error('Failed to delete flight', { description: error.message })
    },
  })

  return {
    deleteFlight: mutation.mutateAsync,
    isPending: mutation.isPending,
  }
}
