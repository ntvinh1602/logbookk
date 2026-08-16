import { supabase } from '@/lib/supabase'

export async function DeleteFlight(flightId: string) {
  const { error } = await supabase
    .schema("flight")
    .from("flights")
    .delete()
    .eq("id", flightId)

  if (error) throw new Error(error.message)
}
