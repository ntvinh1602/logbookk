import { supabase } from '@/lib/supabase'
import { type Database } from "@/types/database.types"

type AirportRow = Database["flight"]["Tables"]["airports"]["Row"]

export type Airport = {
  [K in keyof AirportRow]: NonNullable<AirportRow[K]>
}

export default async function getAirports() {
  const { data, error } = await supabase
    .schema("flight")
    .from("airports")
    .select("id, iata_code, name, lat, lng")

  if (error) throw new Error(error.message)
  return data as Airport[]
}
