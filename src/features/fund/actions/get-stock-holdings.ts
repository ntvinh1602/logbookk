import { createClient } from "@/lib/supabase/client"

export async function getStockHoldings() {
  const { data, error } = await createClient()
    .from('balance_sheet')
    .select('ticker')
    .eq('asset_class', 'stock')

  if (error) throw new Error(error.message)
  return (data ?? []) as {
    ticker: string
  }[]
}
