import { NewsWidget } from '@/features/fund/ui/news'
import StatusLabel from '@/components/status-label'
import type { BSheetView, NewsArticle } from '@/features/fund/fund.types'

interface NewsSectionProps {
  balanceSheet: BSheetView[] | undefined
  news: NewsArticle[] | undefined
  isLoading: boolean
}

export function NewsSection({
  balanceSheet,
  news,
  isLoading,
}: NewsSectionProps) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!balanceSheet || !news) return null

  const tickerSet = new Set(
    balanceSheet
      .filter((r) => r.asset_class === 'stock')
      .map((asset) => asset.ticker),
  )
  const portfolioNews = news.filter((article) =>
    article.tickers?.some((ticker) => tickerSet.has(ticker)),
  )

  return <NewsWidget allNews={news} portfolioNews={portfolioNews} />
}
