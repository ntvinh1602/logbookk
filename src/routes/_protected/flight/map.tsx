import { createFileRoute } from '@tanstack/react-router'
import { useQueries } from '@tanstack/react-query'
import LeafletMap from '@/features/flight/components/map/leaflet-map'
import StatsCarousel from '@/features/flight/components/map/stats-carousel'
import { flights } from '@/features/flight/queries/flights'
import { TopAirportsCard } from '@/features/flight/components/map/top-airports'
import { TopAirlinesCard } from '@/features/flight/components/map/top-airlines'
import { TopAircraftsCard } from '@/features/flight/components/map/top-aircrafts'
import { TopRoutesCard } from '@/features/flight/components/map/top-routes'

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
  ] = useQueries({
    queries: [
      flights.uniqueRoutes(),
      flights.airports(),
      flights.lifetimeStats(),
      flights.topAirports(),
      flights.topAirlines(),
      flights.topAircrafts(),
      flights.topRoutes(),
    ],
  })

  return (
    <div className="flex flex-col gap-8 pb-15">
      <LeafletMap
        data={uniqueRoutesQuery.data ?? []}
        airports={airportsQuery.data ?? []}
      />
      <div className="mx-auto flex w-full max-w-screen-2xl flex-col gap-8">
        {statsQuery.data && <StatsCarousel stats={statsQuery.data} />}
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
      </div>
    </div>
  )
}
