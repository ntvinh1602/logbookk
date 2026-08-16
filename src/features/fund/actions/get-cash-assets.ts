import { createClient } from "@/lib/supabase/client"
import type { Tables } from "@/types/database.types"

export async function getCashAssets() {

  const { data, error } = await createClient()
    .from("assets")
    .select("*")
    .in("asset_class", ["cash", "fund"])

  if (error) throw new Error(error.message)
  return (data ?? []) as Tables<"assets">[]
}
