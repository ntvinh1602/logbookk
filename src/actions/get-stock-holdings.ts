import { supabase } from '@/lib/supabase'

export async function getStockHoldings() {
  const { data, error } = await supabase
    .from('balance_sheet')
    .select('ticker')
    .eq('asset_class', 'stock')

  if (error) throw new Error(error.message)
  return (data ?? []) as {
    ticker: string
  }[]
}
