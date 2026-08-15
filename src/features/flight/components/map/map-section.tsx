import { lazy, Suspense } from 'react'
import { ClientOnly } from '@tanstack/react-router'
import StatusLabel from '@/components/status-label'
import {
  useAirports,
  useRoutesGeoJSON,
} from '@/features/flight/hooks/use-flight-map-data'

// separate module required — this keeps Leaflet out of the server bundle
const LeafletMap = lazy(() => import('@/features/flight/ui/leaflet-map'))

function MapFallback() {
  return <StatusLabel type="loading" className="h-full" />
}

export default function FlightMapSection() {
  const { data: routes, error } = useRoutesGeoJSON()
  const { data: airports } = useAirports()

  if (routes && airports) {
    return (
      <div className="relative min-h-0 flex-1 overflow-hidden isolate">
        <ClientOnly fallback={<MapFallback />}>
          <Suspense fallback={<MapFallback />}>
            <LeafletMap routes={routes} airports={airports} />
          </Suspense>
        </ClientOnly>
      </div>
    )
  }

  return (
    <div className="relative min-h-0 flex-1 overflow-hidden isolate">
      {error ? (
        <StatusLabel
          type="error"
          description={error.message}
          className="h-full"
        />
      ) : (
        <MapFallback />
      )}
    </div>
  )
}
