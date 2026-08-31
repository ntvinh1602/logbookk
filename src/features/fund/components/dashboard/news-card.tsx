import { useState } from 'react'
import StatusLabel from '@/components/status-label'
import type { BSheetView, NewsArticle } from '@/features/fund/fund.types'
import {
  Item,
  ItemContent,
  ItemDescription,
  ItemGroup,
  ItemTitle,
} from '@/components/ui/item'
import { Badge } from '@/components/ui/badge'
import { Clock, Newspaper } from 'lucide-react'
import { formatDistance } from 'date-fns'
import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  CardAction,
} from '@/components/ui/card'
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'
import { ScrollArea } from '@/components/ui/scroll-area'

interface NewsSectionProps {
  balanceSheet: BSheetView[] | undefined
  news: NewsArticle[] | undefined
  isLoading: boolean
}

function ArticleList({ articles }: { articles: NewsArticle[] }) {
  const now = new Date()

  if (articles.length == 0) return <StatusLabel type="empty" />

  return (
    <ItemGroup className="gap-0 px-2">
      {articles.map((article) => (
        <Item key={article.id}>
          <ItemContent className="w-full">
            <ItemTitle
              className="cursor-pointer hover:text-primary transition-colors line-clamp-1"
              onClick={() => window.open(article.url, '_blank')}
            >
              <Badge
                variant="default"
                className="self-start text-xs pointer-events-none font-mono mr-2"
              >
                {article.tickers && article.tickers[0]}
              </Badge>
              {article.title}
            </ItemTitle>
            <ItemDescription className="text-xs">
              {article.excerpt}
            </ItemDescription>
            <ItemDescription className="flex gap-1 pt-1">
              <Badge variant="secondary" className="pointer-events-none">
                <Clock />
                {now &&
                  formatDistance(new Date(article.published_at), now, {
                    addSuffix: true,
                  })}
              </Badge>
              <Badge variant="secondary" className="pointer-events-none">
                <Newspaper />
                {article.source}
              </Badge>
            </ItemDescription>
          </ItemContent>
        </Item>
      ))}
    </ItemGroup>
  )
}

export function NewsCard({
  balanceSheet,
  news,
  isLoading,
}: NewsSectionProps) {
  const [selected, setSelected] = useState<'all' | 'related'>('all')

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

  const articles = selected === 'all' ? news : portfolioNews
  return (
    <Card className="h-140 pb-0">
      <CardHeader>
        <CardTitle>News</CardTitle>
        <CardAction>
          <ToggleGroup
            value={[selected]}
            onValueChange={(value) => {
              if (value.length > 0) setSelected(value[0] as 'all' | 'related')
            }}
            spacing={1}
          >
            <ToggleGroupItem value="related">Related</ToggleGroupItem>
            <ToggleGroupItem value="all">All news</ToggleGroupItem>
          </ToggleGroup>
        </CardAction>
      </CardHeader>
      <CardContent className="px-0 flex min-h-0 flex-1 flex-col">
        <ScrollArea className="h-full w-full">
          <ArticleList articles={articles} />
        </ScrollArea>
      </CardContent>
    </Card>
  )
}
