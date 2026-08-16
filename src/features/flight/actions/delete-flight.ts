import { createClient } from "@/lib/supabase/client"

export async function DeleteFlight(flightId: string) {
  const { error } = await createClient()
    .schema("flight")
    .from("flights")
    .delete()
    .eq("id", flightId)

  if (error) throw new Error(error.message)
}
