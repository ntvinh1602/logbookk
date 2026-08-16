import { supabase } from '@/lib/supabase'
import type { Tables } from "@/types/database.types"

export async function getCashAssets() {
  const { data, error } = await supabase
    .from("assets")
    .select("*")
    .in("asset_class", ["cash", "fund"])

  if (error) throw new Error(error.message)
  return (data ?? []) as Tables<"assets">[]
}
