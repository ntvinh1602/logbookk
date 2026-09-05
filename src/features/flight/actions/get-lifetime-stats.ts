import { createClient } from "@/lib/supabase/client"
import { type Database } from "@/lib/supabase/supabase.types"

type StatsRow = Database["flight"]["Views"]["lifetime_stats"]["Row"]

export type LifetimeStats = {
  [K in keyof StatsRow]: NonNullable<StatsRow[K]>
}

export default async function getLifetimeStats(): Promise<LifetimeStats | null> {
  const { data, error } = await createClient()
    .schema("flight")
    .from("lifetime_stats")
    .select()
    .maybeSingle()

  if (error) throw new Error(error.message)
  if (!data) return null
  return data as LifetimeStats
}
