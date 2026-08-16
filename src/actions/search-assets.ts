import { supabase } from '@/lib/supabase'

export type AssetSearchResult = {
  id: string
  ticker: string
  name: string
}

export async function searchAssets(query: string, assetClass: string) {
  if (!query || query.length < 3) return []
  const { data, error } = await supabase
    .from('assets')
    .select('id, ticker, name')
    .eq('asset_class', assetClass)
    .ilike('ticker', `%${query}%`)
    .limit(20)

  if (error) throw new Error(error.message)
  return (data ?? []) as AssetSearchResult[]
}
