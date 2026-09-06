import { useQuery } from '@tanstack/react-query'
import { getRouteApi } from '@tanstack/react-router'
import { Users, Calendar } from 'lucide-react'
import { flights } from '@/features/flight/queries/flights'
import { FilterSelect } from '@/components/filter/select-options'
import { FilterToggleGroup } from '@/components/filter/toggle-options'
import { FilterSearch } from '@/components/filter/text-search'
import { FieldGroup } from '@/components/ui/field'
import type { FilterState } from '@/features/flight/types'
import { TICKET_CLASS, FLIGHTS_START_YEAR } from '@/features/flight/config'
import { useYearOptions } from '@/hooks/use-year-options'

const routeApi = getRouteApi('/_protected/flight/history')

/**
 * Keeps the URL clean: undefined values are dropped by TanStack, so a filter is
 * only serialized once it differs from its default (all airlines/years, economy,
 * no text search).
 */
function toSearch(filters: FilterState) {
  return {
    year: filters.year ?? undefined,
    airline: filters.airline ?? undefined,
    ticketClass:
      filters.ticketClass === 'eco' ? undefined : filters.ticketClass,
    search: filters.search || undefined,
  }
}

export function HistoryFilter() {
  const search = routeApi.useSearch()
  const navigate = routeApi.useNavigate()

  const filters: FilterState = {
    year: search.year ?? null,
    airline: search.airline ?? null,
    ticketClass: search.ticketClass ?? 'eco',
    search: search.search ?? '',
  }

  const airlinesQuery = useQuery(flights.airlines())

  const airlineOptions: Record<string, { label: string }> = Object.fromEntries(
    (airlinesQuery.data ?? []).map((a) => [a.name, { label: a.name }]),
  )

  const { years, yearOptions } = useYearOptions(FLIGHTS_START_YEAR)

  const setFilter = <TKey extends keyof FilterState>(
    key: TKey,
    value: FilterState[TKey],
  ) => {
    navigate({
      to: '/flight/history',
      search: toSearch({ ...filters, [key]: value }),
    })
  }

  return (
    <FieldGroup className="gap-4">
      <div className="w-full min-w-0 overflow-hidden border-b border-muted md:flex-1">
        <FilterToggleGroup
          value={filters.ticketClass}
          onValueChange={(v) => {
            if (v) setFilter('ticketClass', v as FilterState['ticketClass'])
          }}
          options={TICKET_CLASS}
        />
      </div>

      <div className="flex flex-col xl:flex-row gap-3 w-full">
        <FilterSearch
          placeholder="Flight number"
          value={filters.search}
          onCommit={(v) => setFilter('search', v)}
        />

        <FilterSelect
          icon={Users}
          placeholder="Select an airline"
          value={filters.airline}
          onValueChange={(v) => setFilter('airline', v)}
          options={airlineOptions}
        />

        <FilterSelect
          icon={Calendar}
          placeholder="Year"
          value={filters.year === null ? null : String(filters.year)}
          onValueChange={(v) =>
            setFilter('year', v === null ? null : Number(v))
          }
          options={yearOptions}
          optionsOrder={years.map(String)}
        />
      </div>
    </FieldGroup>
  )
}
