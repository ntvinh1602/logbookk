import { useQuery } from '@tanstack/react-query'
import { getRouteApi } from '@tanstack/react-router'
import { flights } from '@/features/flight/queries/flights'
import { AddFlightForm } from '@/features/flight/form/flightsForm'
import { HistoryFilter } from './history-filter'
import { HistoryBody } from './history-body'

const routeApi = getRouteApi('/_protected/flight/history')

export function HistoryPage() {
  const search = routeApi.useSearch()

  const query = useQuery(
    flights.list({
      year: search.year === undefined ? undefined : String(search.year),
      airline: search.airline,
      isDomestic:
        search.scope === undefined ? undefined : search.scope === 'domestic',
      search: search.search ?? '',
    }),
  )

  return (
    <div className="flex flex-col max-w-screen-lg mx-auto py-15 gap-8">
      <div className="flex justify-between">
        <h1 className="text-2xl font-bold">Flight History</h1>
        <AddFlightForm />
      </div>

      <HistoryFilter />

      <HistoryBody
        data={query.data ?? []}
        isLoading={query.isPending}
        error={query.error}
      />
    </div>
  )
}
