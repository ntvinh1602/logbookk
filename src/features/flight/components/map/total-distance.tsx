import StatusLabel from '@/components/status-label'
import {
  Item,
  ItemContent,
  ItemDescription,
  ItemMedia,
  ItemTitle,
} from '@/components/ui/item'
import type { StatsRow } from '@/features/flight/types'
import { formatNum } from '@/lib/utils'
import { MapPin } from 'lucide-react'

interface Props {
  data: StatsRow | undefined
  isLoading: boolean
}

export default function TotalDistance({ data, isLoading }: Props) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!data) return null

  return (
    <Item variant="outline" className='bg-card'>
      <ItemMedia variant="image">
        <div className="flex rounded-full bg-secondary size-10 items-center justify-center">
          <MapPin className="text-secondary-foreground" />
        </div>
      </ItemMedia>
      <ItemContent>
        <ItemDescription>Total Distance</ItemDescription>
        <ItemTitle className="text-2xl">{`${formatNum(data.distance)} km`}</ItemTitle>
      </ItemContent>
      <ItemContent>
        <ItemTitle>{data.duration}</ItemTitle>
        <ItemDescription>Hours</ItemDescription>
      </ItemContent>
    </Item>
  )
}
