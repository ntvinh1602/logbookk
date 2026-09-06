import type { Database } from '@/lib/supabase/supabase.types'
import type { NonNullableExcept } from '@/lib/utils'

// Tables
export type AircraftRow = Database['dim']['Tables']['aircraft']['Row']
export type AirlineRow = Database['dim']['Tables']['airline']['Row']
export type AirportRow = Database['dim']['Tables']['airport']['Row']
export type FlightsInsert = Database['dwd']['Tables']['flights']['Insert']

// Enums
export type SeatPosition = Database['dim']['Enums']['seat_position']
export type TicketClass = Database['dim']['Enums']['ticket_class']

// Views
export type FlightsSummaryRow = NonNullableExcept<
  Database['dws']['Views']['flights_summary']['Row']
>
export type StatsRow = NonNullableExcept<
  Database['dws']['Views']['lifetime_stats']['Row']
>
export type UniqueRoutes = NonNullableExcept<
  Database['dws']['Views']['unique_routes']['Row']
>

// Front-end
export interface FilterState {
  year: number | null // "all" or a year like 2024
  airline: string | null // "all" or an airline name
  ticketClass: TicketClass // selected seat type value
  search: string // flight number search
}

export interface FlightsQueryParams {
  year?: string | null
  airline?: string | null
  ticketClass?: Database['dim']['Enums']['ticket_class']
  search?: string
}

export interface FlightUpsertInput {
  airlineCode: string
  departureCode: string
  departureLocal: string
  departureTz: string
  arrivalCode: string
  arrivalLocal: string
  arrivalTz: string
  flightNumber: string
  ticketClass: Database['dim']['Enums']['ticket_class']
  aircraftType: string | null
  seatNumber: string | null
  seatPosition: Database['dim']['Enums']['seat_position'] | null
  tailNumber: string | null
}
