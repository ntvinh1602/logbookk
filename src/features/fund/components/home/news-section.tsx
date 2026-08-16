import { useMemo } from 'react'
import { NewsWidget } from '@/features/fund/ui/news'
import { useDashboardNews } from '@/features/fund/hooks/use-dashboard-data'
import StatusLabel from '@/components/status-label'
import type { NewsArticle } from '@/features/fund/fund.types'

function usePortfolioNews(news: NewsArticle[], stocks: { ticker: string }[]) {
  return useMemo(() => {
    const tickerSet = new Set(stocks.map((asset) => asset.ticker))
    return news.filter((article) =>
      article.tickers?.some((ticker) => tickerSet.has(ticker)),
    )
  }, [news, stocks])
}

export function NewsSection() {
  const { data, error, isLoading } = useDashboardNews()
  const portfolioNews = usePortfolioNews(data?.news ?? [], data?.stocks ?? [])

  if (isLoading) return <StatusLabel type="loading" />
  if (error || !data) return <StatusLabel type="error" />

  return <NewsWidget allNews={data.news} portfolioNews={portfolioNews} />
}
