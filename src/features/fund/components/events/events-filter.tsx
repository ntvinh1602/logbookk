import { getRouteApi } from '@tanstack/react-router'
import { format } from 'date-fns'
import { Calendar, Settings, X } from 'lucide-react'
import { FilterSelect } from '@/components/filter/select-options'
import { DateRangePicker } from '@/components/filter/date-picker'
import { Button } from '@/components/ui/button'
import {
  DEFAULT_TIME_PRESET,
  EVENT_CATEGORY,
  EVENT_DATE_KEY,
  TIME_PRESET,
} from '@/features/fund/config'
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
  // from/to are inert unless the period is custom, so they only matter here
  // when the period itself is already non-default.
  const isDefault = period === DEFAULT_TIME_PRESET && !currentOp

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
  // The patch overrides every key `go` seeds, so explicit undefined clears
  // op/from/to and the search falls back to its schema defaults.
  const handleClear = () =>
    go({
      period: DEFAULT_TIME_PRESET,
      from: undefined,
      to: undefined,
      op: undefined,
    })

  return (
    <div className="flex flex-col xl:flex-row gap-3 w-full">
      {!isDefault && (
        <Button variant="outline" onClick={handleClear}>
          <X />
          Reset
        </Button>
      )}
      <div className="w-auto min-w-30 flex-none">
        <FilterSelect
          icon={Settings}
          placeholder="Choose operation"
          value={currentOp ? currentOp : null}
          onValueChange={(v) => go({ op: v ?? undefined })}
          options={ops}
        />
      </div>
      <div className="flex flex-col md:flex-row w-full gap-3">
        <FilterSelect
          icon={Calendar}
          placeholder="period"
          value={period}
          onValueChange={handlePresetChange}
          options={TIME_PRESET}
        />

        <DateRangePicker
          dateFrom={range.displayFrom}
          dateTo={range.displayTo}
          onDateFromChange={(date) =>
            go({ from: format(date, EVENT_DATE_KEY) })
          }
          onDateToChange={(date) => go({ to: format(date, EVENT_DATE_KEY) })}
          disabled={!isCustom}
        />
      </div>
    </div>
  )
}
