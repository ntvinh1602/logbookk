import { createFileRoute } from '@tanstack/react-router'
import { useQueries } from '@tanstack/react-query'
import LeafletMap from '@/features/flight/components/map/leaflet-map'
import StatsCarousel from '@/features/flight/components/map/stats-carousel'
import { flights } from '@/features/flight/queries/flights'

export const Route = createFileRoute('/_protected/flight/map')({
  component: RouteComponent,
})

function RouteComponent() {
  const [geojsonQuery, airportsQuery, statsQuery] = useQueries({
    queries: [flights.geojson(), flights.airports(), flights.lifetimeStats()],
  })

  return (
    <div className="flex flex-col gap-8 py-15">
      <div className="mx-auto w-full max-w-screen-2xl">
        <h1 className="text-2xl font-bold text-left">Flights Map</h1>
      </div>

      <LeafletMap
        data={geojsonQuery.data ?? []}
        airports={airportsQuery.data ?? []}
      />
      <div className="mx-auto flex w-full max-w-screen-2xl flex-col gap-8">
        {statsQuery.data && <StatsCarousel stats={statsQuery.data} />}
      </div>
    </div>
  )
}
