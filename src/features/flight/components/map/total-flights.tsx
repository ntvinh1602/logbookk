import StatusLabel from '@/components/status-label'
import {
  Item,
  ItemContent,
  ItemDescription,
  ItemMedia,
  ItemTitle,
} from '@/components/ui/item'
import type { StatsRow } from '@/features/flight/types'
import { Plane } from 'lucide-react'

interface Props {
  data: StatsRow | undefined
  isLoading: boolean
}

export default function TotalFlights({ data, isLoading }: Props) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!data) return null

  return (
    <Item variant="outline" className="bg-card">
      <ItemMedia variant="image">
        <div className="flex rounded-full bg-secondary size-10 items-center justify-center">
          <Plane className="text-secondary-foreground" />
        </div>
      </ItemMedia>
      <ItemContent>
        <ItemDescription>Total Flights</ItemDescription>
        <ItemTitle className="text-2xl">{data.flights}</ItemTitle>
      </ItemContent>
      <ItemContent>
        <ItemTitle>{data.intl}</ItemTitle>
        <ItemDescription>International</ItemDescription>
      </ItemContent>
      <ItemContent>
        <ItemTitle>{data.domestic}</ItemTitle>
        <ItemDescription>Domestic</ItemDescription>
      </ItemContent>
    </Item>
  )
}
