import { keepPreviousData, queryOptions } from '@tanstack/react-query'
import {
  getAircrafts,
  getAirlines,
  getAirports,
  getFlights,
  getLifetimeStats,
  getTopAircrafts,
  getTopAirlines,
  getTopAirports,
  getTopRoutes,
  getUniqueRoutes,
} from '@/features/flight/api.supabase'
import type { FlightsQueryParams } from '@/features/flight/types'

export const flightDwdKeys = {
  all: ['flightdwd'] as const,

  uniqueRoutes: () => [...flightDwdKeys.all, 'uniqueRoutes'] as const,
  lifetimeStats: () => [...flightDwdKeys.all, 'lifetimeStats'] as const,
  topAirports: () => [...flightDwdKeys.all, 'top-airport'] as const,
  topAirlines: () => [...flightDwdKeys.all, 'top-airlines'] as const,
  topAircrafts: () => [...flightDwdKeys.all, 'top-aircrafts'] as const,
  topRoutes: () => [...flightDwdKeys.all, 'top-routes'] as const,
  list: (params: FlightsQueryParams) =>
    [...flightDwdKeys.all, 'list', params] as const,
}

export const flightDimKeys = {
  all: ['flightdim'] as const,

  aircrafts: () => [...flightDimKeys.all, 'aircrafts'] as const,
  airlines: () => [...flightDimKeys.all, 'airlines'] as const,
  airports: () => [...flightDimKeys.all, 'airports'] as const,
}

export const flights = {
  aircrafts: () => {
    return queryOptions({
      queryKey: flightDimKeys.aircrafts(),
      queryFn: () => getAircrafts(),
    })
  },

  airlines: () => {
    return queryOptions({
      queryKey: flightDimKeys.airlines(),
      queryFn: () => getAirlines(),
    })
  },

  airports: () => {
    return queryOptions({
      queryKey: flightDimKeys.airports(),
      queryFn: () => getAirports(),
    })
  },

  uniqueRoutes: () => {
    return queryOptions({
      queryKey: flightDwdKeys.uniqueRoutes(),
      queryFn: () => getUniqueRoutes(),
    })
  },

  lifetimeStats: () => {
    return queryOptions({
      queryKey: flightDwdKeys.lifetimeStats(),
      queryFn: () => getLifetimeStats(),
    })
  },

  topAirports: () => {
    return queryOptions({
      queryKey: flightDwdKeys.topAirports(),
      queryFn: () => getTopAirports(),
    })
  },

  topAirlines: () => {
    return queryOptions({
      queryKey: flightDwdKeys.topAirlines(),
      queryFn: () => getTopAirlines(),
    })
  },

  topAircrafts: () => {
    return queryOptions({
      queryKey: flightDwdKeys.topAircrafts(),
      queryFn: () => getTopAircrafts(),
    })
  },

  topRoutes: () => {
    return queryOptions({
      queryKey: flightDwdKeys.topRoutes(),
      queryFn: () => getTopRoutes(),
    })
  },

  list: (params: FlightsQueryParams = {}) => {
    return queryOptions({
      queryKey: flightDwdKeys.list(params),
      queryFn: () => getFlights(params),
      placeholderData: keepPreviousData,
    })
  },
}
