import { useMutation } from "@tanstack/react-query"
import { toast } from "sonner"
import { DeleteFlight } from "@/features/flight/actions/delete-flight"

export function useDeleteFlight(onSuccess?: () => void) {
  const mutation = useMutation({
    mutationFn: DeleteFlight,
    onSuccess: () => {
      toast.success("Flight deleted successfully")
      onSuccess?.()
    },
    onError: (error: Error) => {
      toast.error(error.message || "Failed to delete flight")
    },
  })

  return {
    deleteFlight: mutation.mutateAsync,
    isPending: mutation.isPending,
    error: mutation.error,
  }
}
