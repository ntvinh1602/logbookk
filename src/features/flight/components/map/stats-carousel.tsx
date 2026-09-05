import { formatNum } from '@/lib/utils'
import {
  Clock,
  Earth,
  Plane,
  PlaneTakeoff,
  Route,
  TicketsPlane,
} from 'lucide-react'
import {
  Item,
  ItemContent,
  ItemDescription,
  ItemGroup,
  ItemMedia,
  ItemTitle,
} from '@/components/ui/item'
import type { StatsRow } from '@/lib/supabase/api/types'

export default function StatsCarousel({ stats }: { stats: StatsRow }) {
  const statItems = [
    {
      title: 'Flights',
      figure: stats.flights_count,
      icon: TicketsPlane,
    },
    {
      title: 'Airports',
      figure: stats.airports_count,
      icon: PlaneTakeoff,
    },
    {
      title: 'Countries',
      figure: stats.country_count,
      icon: Earth,
    },
    {
      title: 'Aircraft Types',
      figure: stats.type_count,
      icon: Plane,
    },
    {
      title: 'Distance',
      figure: `${formatNum(stats.total_distance)} km`,
      icon: Route,
    },
    {
      title: 'Duration',
      figure: `${stats.total_duration} hours`,
      icon: Clock,
    },
  ]

  return (
    <ItemGroup className='flex-row gap-2'>
      {statItems.map((stat) => (
        <Item variant="outline" key={stat.title}>
          <ItemMedia variant="icon">
            <stat.icon />
          </ItemMedia>
          <ItemContent>
            <ItemTitle className="text-xl xl:text-2xl">{stat.figure}</ItemTitle>
            <ItemDescription>{stat.title}</ItemDescription>
          </ItemContent>
        </Item>
      ))}
    </ItemGroup>
  )
}
