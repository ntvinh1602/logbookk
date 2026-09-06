import {
  Item,
  ItemContent,
  ItemDescription,
  ItemGroup,
  ItemMedia,
  ItemTitle,
} from '@/components/ui/item'
import type { StatsRow } from '@/features/flight/types'
import { FLIGHTS_STATS } from '@/features/flight/config'

export default function StatsCarousel({ stats }: { stats: StatsRow }) {
  return (
    <ItemGroup className="flex-row gap-2">
      {FLIGHTS_STATS.map((s) => {
        const value = s.getValue(stats)
        if (!value) return 'N/A'
        return (
          <Item variant="outline" key={s.label}>
            <ItemMedia variant="icon">
              <s.icon />
            </ItemMedia>
            <ItemContent>
              <ItemTitle className="text-2xl">{value}</ItemTitle>
              <ItemDescription>{s.label}</ItemDescription>
            </ItemContent>
          </Item>
        )
      })}
    </ItemGroup>
  )
}
