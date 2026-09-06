import { getRouteApi } from '@tanstack/react-router'
import { format } from 'date-fns'
import { Calendar, Settings } from 'lucide-react'
import {
  SelectAllEnabled,
  SingleOptionSelect,
} from '@/components/filter/select-options'
import { DateRangePicker } from '@/components/filter/date-picker'
import { EVENT_CATEGORY, EVENT_DATE_KEY, TIME_PRESET } from '@/features/fund/config'
import type { Events, TimePresets } from '@/features/fund/config'
import { getValidOp } from '@/features/fund/utils'
import { useEventDateRange } from '@/features/fund/hooks/use-event-date-range'

const routeApi = getRouteApi('/_protected/fund/events/$event')

type EventsSearch = ReturnType<typeof routeApi.useSearch>

export function EventsFilter({ event }: { event: Events }) {
  const navigate = routeApi.useNavigate()
  const search = routeApi.useSearch()
  const period = search.period
  const range = useEventDateRange(search)
  const ops = EVENT_CATEGORY[event].operations
  const currentOp = getValidOp(ops, search.op)
  const isCustom = period === 'custom'

  // Always submits the full search object so stale keys from a previous state
  // are replaced (explicit undefined clears a key under TanStack's merge).
  const go = (patch: Partial<EventsSearch>) =>
    navigate({
      to: '/fund/events/$event',
      params: { event },
      search: {
        period,
        from: isCustom ? search.from : undefined,
        to: isCustom ? search.to : undefined,
        op: currentOp,
        ...patch,
      },
    })
  const handlePresetChange = (value: string) => {
    if (value === 'custom') {
      go({
        period: 'custom',
        from: format(range.displayFrom, EVENT_DATE_KEY),
        to: format(range.displayTo, EVENT_DATE_KEY),
      })
    } else {
      go({
        period: value as TimePresets,
        from: undefined,
        to: undefined,
      })
    }
  }

  return (
    <div className="flex flex-col xl:flex-row gap-3 w-full">
      <div className="w-full flex-none md:w-auto">
        <SelectAllEnabled
          icon={Settings}
          placeholder="Operation"
          value={currentOp ?? null}
          onValueChange={(v) => go({ op: v ?? undefined })}
          allLabel="All operations"
          options={ops}
        />
      </div>
      <div className="flex flex-col md:flex-row w-full gap-3">
        <SingleOptionSelect
          icon={Calendar}
          placeholder="period"
          value={period}
          onValueChange={handlePresetChange}
          options={TIME_PRESET}
        />

        <DateRangePicker
          dateFrom={range.displayFrom}
          dateTo={range.displayTo}
          onDateFromChange={(date) => go({ from: format(date, EVENT_DATE_KEY) })}
          onDateToChange={(date) => go({ to: format(date, EVENT_DATE_KEY) })}
          disabled={!isCustom}
        />
      </div>
    </div>
  )
}
