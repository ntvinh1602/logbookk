import { createClient } from "@/lib/supabase/client"
import { type Database } from "@/types/database.types"

type AircraftRow = Database["flight"]["Tables"]["aircrafts"]["Row"]

export type Aircraft = {
  [K in keyof AircraftRow]: NonNullable<AircraftRow[K]>
}

export default async function getAircrafts() {
  const { data, error } = await createClient()
    .schema("flight")
    .from("aircrafts")
    .select()
    .order("icao_code")

  if (error) throw new Error(error.message)
  return data as Aircraft[]
}
