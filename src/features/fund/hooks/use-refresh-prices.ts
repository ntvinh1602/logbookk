import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useRef } from 'react'
import { toast } from 'sonner'

import { refreshPrices } from '@/features/fund/api/prices'
import { invalidateFundQueries } from '@/features/fund/queries/invalidate'

export function useRefreshPrices() {
  const queryClient = useQueryClient()
  const loadingToastId = useRef<string | number | undefined>(undefined)

  const mutation = useMutation({
    mutationFn: refreshPrices,
    onMutate: () => {
      loadingToastId.current = toast.loading('Fetching latest prices...')
    },
    onSuccess: async (data) => {
      await invalidateFundQueries(queryClient)

      toast.success(data.message, {
        id: loadingToastId.current,
        description: `Updated items: ${data.updated}`,
      })
    },
    onError: (error: Error) => {
      toast.error(error.message || 'Failed to update prices', {
        id: loadingToastId.current,
      })
    },
  })

  return {
    refreshPrices: mutation.mutateAsync,
    isPending: mutation.isPending,
  }
}
