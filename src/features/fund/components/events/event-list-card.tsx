import type { ReactNode } from 'react'
import StatusLabel from '@/components/status-label'
import { ItemGroup } from '@/components/ui/item'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'

interface EventListCardProps {
  count: number
  isLoading: boolean
  error: Error | null
  children: ReactNode
}

/** Shared chrome for a transaction list: status labels, Card, and the row group. */
export function EventListCard({
  count,
  isLoading,
  error,
  children,
}: EventListCardProps) {
  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (count === 0) return <StatusLabel type="empty" />

  return (
    <Card className="gap-4">
      <CardHeader>
        <CardTitle>Event List</CardTitle>
        <CardDescription>{count} transactions</CardDescription>
      </CardHeader>
      <CardContent className="px-0">
        <ItemGroup className="gap-0">{children}</ItemGroup>
      </CardContent>
    </Card>
  )
}
