import { createClient } from "@/lib/supabase/client"
import { type Database } from "@/types/database.types"

type AirportRow = Database["flight"]["Tables"]["airports"]["Row"]

export type Airport = {
  [K in keyof AirportRow]: NonNullable<AirportRow[K]>
}

export default async function getAirports() {
  const { data, error } = await createClient()
    .schema("flight")
    .from("airports")
    .select()

  if (error) throw new Error(error.message)
  return data as Airport[]
}
