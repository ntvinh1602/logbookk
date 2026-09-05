import { keepPreviousData, queryOptions } from '@tanstack/react-query'
import {
  getAircrafts,
  getAirlines,
  getAirports,
  getFlights,
  getLifetimeStats,
  getRoutesGeoJSON,
} from '@/lib/supabase/api/flight.supabase'
import type { FlightsQueryParams } from '@/lib/supabase/api/flight.supabase'

export const flightKeys = {
  all: ['flights'] as const,

  aircrafts: () => [...flightKeys.all, 'aircrafts'] as const,

  airlines: () => [...flightKeys.all, 'airlines'] as const,

  airports: () => [...flightKeys.all, 'airports'] as const,

  geojson: () => [...flightKeys.all, 'geojson'] as const,

  lifetimeStats: () => [...flightKeys.all, 'lifetimeStats'] as const,

  list: (params: FlightsQueryParams) =>
    [...flightKeys.all, 'list', params] as const,
}

export const flights = {
  aircrafts: () => {
    return queryOptions({
      queryKey: flightKeys.aircrafts(),
      queryFn: () => getAircrafts(),
    })
  },

  airlines: () => {
    return queryOptions({
      queryKey: flightKeys.airlines(),
      queryFn: () => getAirlines(),
    })
  },

  airports: () => {
    return queryOptions({
      queryKey: flightKeys.airports(),
      queryFn: () => getAirports(),
    })
  },

  geojson: () => {
    return queryOptions({
      queryKey: flightKeys.geojson(),
      queryFn: () => getRoutesGeoJSON(),
    })
  },

  lifetimeStats: () => {
    return queryOptions({
      queryKey: flightKeys.lifetimeStats(),
      queryFn: () => getLifetimeStats(),
    })
  },

  list: (params: FlightsQueryParams = {}) => {
    return queryOptions({
      queryKey: flightKeys.list(params),
      queryFn: () => getFlights(params),
      placeholderData: keepPreviousData,
    })
  },
}
