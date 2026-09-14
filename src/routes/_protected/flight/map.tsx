import { createFileRoute } from '@tanstack/react-router'
import { useQueries } from '@tanstack/react-query'
import LeafletMap from '@/features/flight/components/map/leaflet-map'
import { flights } from '@/features/flight/queries/flights'
import { TopAirportsCard } from '@/features/flight/components/map/top-airports'
import { TopAirlinesCard } from '@/features/flight/components/map/top-airlines'
import { TopAircraftsCard } from '@/features/flight/components/map/top-aircrafts'
import { TopRoutesCard } from '@/features/flight/components/map/top-routes'
import { FlightByYear } from '@/features/flight/components/map/flight-by-year'
import { FlightByMonth } from '@/features/flight/components/map/flight-by-month'
import { FlightByWeekday } from '@/features/flight/components/map/flight-by-weekday'
import TotalFlights from '@/features/flight/components/map/total-flights'
import TotalDistance from '@/features/flight/components/map/total-distance'
import { SeatCard } from '@/features/flight/components/map/seat'

export const Route = createFileRoute('/_protected/flight/map')({
  component: RouteComponent,
})

function RouteComponent() {
  const [
    uniqueRoutesQuery,
    airportsQuery,
    statsQuery,
    topAirportsQuery,
    topAirlinesQuery,
    topAircraftsQuery,
    topRoutesQuery,
    flightsByYearQuery,
    flightsByMonthQuery,
    flightsByWeekdayQuery,
  ] = useQueries({
    queries: [
      flights.uniqueRoutes(),
      flights.airports(),
      flights.lifetimeStats(),
      flights.topAirports(),
      flights.topAirlines(),
      flights.topAircrafts(),
      flights.topRoutes(),
      flights.byYear(),
      flights.byMonth(),
      flights.byWeekday(),
    ],
  })

  return (
    <div className="flex flex-col gap-8 pb-15">
      <LeafletMap
        data={uniqueRoutesQuery.data ?? []}
        airports={airportsQuery.data ?? []}
      />
      <div className="mx-auto flex w-full max-w-screen-2xl flex-col gap-4">
        <div className="grid grid-cols-3 gap-2">
          <TotalFlights
            data={statsQuery.data}
            isLoading={statsQuery.isLoading}
          />
          <TotalDistance
            data={statsQuery.data}
            isLoading={statsQuery.isLoading}
          />
          <SeatCard data={statsQuery.data} isLoading={statsQuery.isLoading} />
        </div>
        <div className="grid grid-cols-4 gap-2">
          <TopAirportsCard
            airportData={topAirportsQuery.data}
            lifetimeStats={statsQuery.data}
            isLoading={topAirportsQuery.isLoading || statsQuery.isLoading}
          />
          <TopAirlinesCard
            airlinesData={topAirlinesQuery.data}
            lifetimeStats={statsQuery.data}
            isLoading={topAirlinesQuery.isLoading || statsQuery.isLoading}
          />
          <TopAircraftsCard
            aircraftsData={topAircraftsQuery.data}
            lifetimeStats={statsQuery.data}
            isLoading={topAircraftsQuery.isLoading || statsQuery.isLoading}
          />
          <TopRoutesCard
            routesData={topRoutesQuery.data}
            lifetimeStats={statsQuery.data}
            isLoading={topRoutesQuery.isLoading || statsQuery.isLoading}
          />
        </div>
        <div className="grid grid-cols-3 gap-2">
          <FlightByYear
            data={flightsByYearQuery.data}
            isLoading={flightsByYearQuery.isLoading}
          />
          <FlightByMonth
            data={flightsByMonthQuery.data}
            isLoading={flightsByMonthQuery.isLoading}
          />
          <FlightByWeekday
            data={flightsByWeekdayQuery.data}
            isLoading={flightsByWeekdayQuery.isLoading}
          />
        </div>
      </div>
    </div>
  )
}
