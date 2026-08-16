import { createClient } from "@/lib/supabase/client"
import { type Database } from "@/types/database.types"

type AirlineRow = Database["flight"]["Tables"]["airlines"]["Row"]

export type Airline = {
  [K in keyof AirlineRow]: NonNullable<AirlineRow[K]>
}

export default async function getAirlines() {
  const { data, error } = await createClient()
    .schema("flight")
    .from("airlines")
    .select("*")
    .order("name")

  if (error) throw new Error(error.message)
  return data as Airline[]
}
