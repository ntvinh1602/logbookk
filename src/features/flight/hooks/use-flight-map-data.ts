import { useQuery } from '@tanstack/react-query'
import getAirports from '@/features/flight/actions/get-airports'
import type { Airport } from '@/features/flight/actions/get-airports'
import getRoutesGeoJSON from '@/features/flight/actions/get-geojson-routes'
import type { RoutesGeoJSONProperties } from '@/features/flight/actions/get-geojson-routes'
import getLifetimeStats from '@/features/flight/actions/get-lifetime-stats'
import type { LifetimeStats } from '@/features/flight/actions/get-lifetime-stats'
import type { FeatureCollection, LineString } from 'geojson'

export function useLifetimeStats() {
  return useQuery<LifetimeStats | null, Error>({
    queryKey: ['flight-lifetime-stats'],
    queryFn: () => getLifetimeStats(),
    staleTime: Infinity,
  })
}

export function useRoutesGeoJSON() {
  return useQuery<
    FeatureCollection<LineString, RoutesGeoJSONProperties>,
    Error
  >({
    queryKey: ['flight-routes-geojson'],
    queryFn: () => getRoutesGeoJSON(),
    staleTime: Infinity,
  })
}

export function useAirports() {
  return useQuery<Airport[], Error>({
    queryKey: ['flight-airports'],
    queryFn: () => getAirports(),
    staleTime: Infinity,
  })
}
