import { keepPreviousData, queryOptions } from '@tanstack/react-query'
import {
  getAircrafts,
  getAirlines,
  getAirports,
  getFlights,
  getLifetimeStats,
  getUniqueRoutes,
} from '@/features/flight/api.supabase'
import type { FlightsQueryParams } from '@/features/flight/types'

export const flightKeys = {
  all: ['flights'] as const,

  aircrafts: () => [...flightKeys.all, 'aircrafts'] as const,

  airlines: () => [...flightKeys.all, 'airlines'] as const,

  airports: () => [...flightKeys.all, 'airports'] as const,

  uniqueRoutes: () => [...flightKeys.all, 'uniqueRoutes'] as const,

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

  uniqueRoutes: () => {
    return queryOptions({
      queryKey: flightKeys.uniqueRoutes(),
      queryFn: () => getUniqueRoutes(),
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
