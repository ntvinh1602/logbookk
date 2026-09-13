import { useQuery } from '@tanstack/react-query'
import { getRouteApi } from '@tanstack/react-router'
import { Users, Calendar, Globe, X } from 'lucide-react'
import { flights } from '@/features/flight/queries/flights'
import { FilterSelect } from '@/components/filter/select-options'
import { FilterSearch } from '@/components/filter/text-search'
import { Button } from '@/components/ui/button'
import { FieldGroup } from '@/components/ui/field'
import type { FilterState, FlightScope } from '@/features/flight/types'
import { FLIGHT_SCOPE, FLIGHTS_START_YEAR } from '@/features/flight/config'
import { useYearOptions } from '@/hooks/use-year-options'

const routeApi = getRouteApi('/_protected/flight/history')

/**
 * Keeps the URL clean: undefined values are dropped by TanStack, so a filter is
 * only serialized once it is set (all airlines/years/scopes, no text search).
 */
function toSearch(filters: FilterState) {
  return {
    year: filters.year ?? undefined,
    airline: filters.airline ?? undefined,
    scope: filters.scope ?? undefined,
    search: filters.search || undefined,
  }
}

const DEFAULT_FILTERS: FilterState = {
  year: null,
  airline: null,
  scope: null,
  search: '',
}

/** True when the URL carries no filter, so there is nothing to reset. */
function isDefaultFilters(filters: FilterState) {
  return (
    filters.year === DEFAULT_FILTERS.year &&
    filters.airline === DEFAULT_FILTERS.airline &&
    filters.scope === DEFAULT_FILTERS.scope &&
    filters.search === DEFAULT_FILTERS.search
  )
}

export function HistoryFilter() {
  const search = routeApi.useSearch()
  const navigate = routeApi.useNavigate()

  const filters: FilterState = {
    year: search.year ?? null,
    airline: search.airline ?? null,
    scope: search.scope ?? null,
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

  const isDefault = isDefaultFilters(filters)

  // The defaults all serialize to undefined, so this clears every search key.
  const resetFilters = () =>
    navigate({ to: '/flight/history', search: toSearch(DEFAULT_FILTERS) })

  return (
    <FieldGroup className="gap-4">
      <div className="flex flex-col xl:flex-row gap-3 w-full">
        {!isDefault && (
          <Button variant="outline" onClick={resetFilters}>
            <X />
            Reset
          </Button>
        )}

        <FilterSearch
          placeholder="Flight number"
          value={filters.search}
          onCommit={(v) => setFilter('search', v)}
        />

        <FilterSelect
          icon={Globe}
          placeholder="All flights"
          value={filters.scope}
          onValueChange={(v) => setFilter('scope', v as FlightScope)}
          options={FLIGHT_SCOPE}
        />

        <FilterSelect
          icon={Users}
          placeholder="All airlines"
          value={filters.airline}
          onValueChange={(v) => setFilter('airline', v)}
          options={airlineOptions}
        />

        <FilterSelect
          icon={Calendar}
          placeholder="All years"
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
