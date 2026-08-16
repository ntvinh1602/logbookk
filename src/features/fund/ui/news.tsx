import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  CardAction,
} from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { formatDistance } from 'date-fns'
import { ScrollArea } from '@/components/ui/scroll-area'
import type { NewsArticle } from '@/features/fund/fund.types'
import {
  Item,
  ItemContent,
  ItemDescription,
  ItemGroup,
  ItemSeparator,
  ItemTitle,
} from '@/components/ui/item'
import { useState } from 'react'
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'
import StatusLabel from '@/components/status-label'
import { Clock, Newspaper } from 'lucide-react'
import { Button } from '@/components/ui/button'

type NewsWidgetProps = {
  allNews: NewsArticle[]
  portfolioNews: NewsArticle[]
}

function ArticleList({ articles }: { articles: NewsArticle[] }) {
  const now = new Date()

  if (articles.length == 0) return <StatusLabel type="empty" />

  return (
    <ItemGroup className="gap-0">
      {articles.map((article) => (
        <div>
          <ItemSeparator />
          <Item key={article.id} size="default" className="px-0 py-1">
            <Button
              variant="secondary"
              className="self-start min-w-12 text-xs pointer-events-none"
              size="sm"
            >
              {article.tickers && article.tickers[0]}
            </Button>

            <ItemContent className="w-full">
              <ItemTitle
                className="cursor-pointer hover:text-primary transition-colors"
                onClick={() => window.open(article.url, '_blank')}
              >
                {article.title}
              </ItemTitle>
              <ItemDescription className="text-xs">
                {article.excerpt}
              </ItemDescription>
              <ItemDescription className="-ml-2">
                <Badge variant="ghost" className='pointer-events-none'>
                  <Newspaper />
                  {article.source}
                </Badge>
                <Badge variant="ghost" className='pointer-events-none'>
                  <Clock />
                  {now &&
                    formatDistance(new Date(article.published_at), now, {
                      addSuffix: true,
                    })}
                </Badge>
              </ItemDescription>
            </ItemContent>
          </Item>
        </div>
      ))}
    </ItemGroup>
  )
}

export function NewsWidget({ allNews, portfolioNews }: NewsWidgetProps) {
  const [selected, setSelected] = useState<'all' | 'related'>('all')
  const articles = selected === 'all' ? allNews : portfolioNews

  return (
    <Card className="h-120">
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
      <CardContent className="flex min-h-0 flex-1 flex-col">
        <ScrollArea className="h-full w-full">
          <ArticleList articles={articles} />
        </ScrollArea>
      </CardContent>
    </Card>
  )
}
