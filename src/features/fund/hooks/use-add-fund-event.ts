import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'

import { invalidateFundQueries } from '../queries/invalidate'

interface AddFundEventOptions<TInput> {
  mutationFn: (input: TInput) => Promise<void>
  successMessage: string
  successDescription?: string | ((input: TInput) => string | undefined)
}

/**
 * Shared mutation wrapper for the fund event forms. Owns the success/error
 * toasts and invalidation so forms only map form values to the RPC payload.
 */
export function useAddFundEvent<TInput>({
  mutationFn,
  successMessage,
  successDescription,
}: AddFundEventOptions<TInput>) {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn,
    onSuccess: async (_data, variables) => {
      await invalidateFundQueries(queryClient)

      const description =
        typeof successDescription === 'function'
          ? successDescription(variables)
          : successDescription

      toast.success(successMessage, description ? { description } : undefined)
    },
    onError: (error: Error) => {
      toast.error('Failed to add transaction', {
        description: error.message,
      })
    },
  })

  return {
    addEvent: mutation.mutateAsync,
    isPending: mutation.isPending,
  }
}
