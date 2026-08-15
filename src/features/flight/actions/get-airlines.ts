import { supabase } from '@/lib/supabase'
import { type Database } from "@/types/database.types"

type AirlineRow = Database["flight"]["Tables"]["airlines"]["Row"]

export type Airline = {
  [K in keyof AirlineRow]: NonNullable<AirlineRow[K]>
}

export default async function getAirlines() {
  const { data, error } = await supabase
    .schema("flight")
    .from("airlines")
    .select("*")
    .order("name")

  if (error) throw new Error(error.message)
  return data as Airline[]
}
