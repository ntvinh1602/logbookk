import { createClient } from '@/lib/supabase/client'
import { localToUtc } from '@/lib/utils'
import type {
  AircraftRow,
  AirlineRow,
  AirportRow,
  FlightsByMonth,
  FlightsByWeekday,
  FlightsByYear,
  FlightsInsert,
  FlightsQueryParams,
  FlightsSummaryRow,
  FlightUpsertInput,
  StatsRow,
  TopAircrafts,
  TopAirlines,
  TopAirports,
  TopRoutes,
  UniqueRoutes,
} from '@/features/flight/types'

// Reads

export async function getFlights(params: FlightsQueryParams = {}) {
  const supabase = createClient()
  const { year, airline, isDomestic, search } = params

  let query = supabase.schema('dws').from('flights_summary').select('*')

  if (year) {
    query = query
      .gte('departure_time', `${year}-01-01`)
      .lte('departure_time', `${year}-12-31`)
  }

  if (airline) {
    query = query.eq('airline_name', airline)
  }

  if (isDomestic !== undefined) {
    query = query.eq('is_domestic', isDomestic)
  }

  if (search) {
    query = query.ilike('flight_number', `%${search}%`)
  }

  const { data, error } = await query.order('departure_time', {
    ascending: false,
  })

  if (error) throw new Error(error.message)
  return data as FlightsSummaryRow[]
}

export async function getAircrafts() {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dim').from('aircraft').select()

  if (error) throw new Error(error.message)
  return data as AircraftRow[]
}

export async function getAirlines() {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dim').from('airline').select()

  if (error) throw new Error(error.message)
  return data as AirlineRow[]
}

export async function getAirports() {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dim').from('airport').select()

  if (error) throw new Error(error.message)
  return data as AirportRow[]
}

export async function getUniqueRoutes() {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .from('unique_routes')
    .select()

  if (error) throw new Error(error.message)

  return data as UniqueRoutes[]
}

export async function getLifetimeStats(): Promise<StatsRow> {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .from('lifetime_stats')
    .select()
    .single()

  if (error) throw new Error(error.message)
  return data as StatsRow
}

export async function getTopAirports(): Promise<TopAirports[]> {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .rpc('get_top_airports', {})

  if (error) throw new Error(error.message)
  return data as TopAirports[]
}

export async function getTopAirlines(): Promise<TopAirlines[]> {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .rpc('get_top_airlines', {})

  if (error) throw new Error(error.message)
  return data as TopAirlines[]
}

export async function getTopAircrafts(): Promise<TopAircrafts[]> {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .rpc('get_top_aircrafts', {})

  if (error) throw new Error(error.message)
  return data as TopAircrafts[]
}

export async function getTopRoutes(): Promise<TopRoutes[]> {
  const supabase = createClient()

  const { data, error } = await supabase.schema('dws').rpc('get_top_routes', {})

  if (error) throw new Error(error.message)
  return data as TopRoutes[]
}

export async function getFlightsByYear(): Promise<FlightsByYear[]> {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .rpc('get_flights_by_year', {})

  if (error) throw new Error(error.message)
  return data as FlightsByYear[]
}

export async function getFlightsByMonth(): Promise<FlightsByMonth[]> {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .rpc('get_flights_by_month', {})

  if (error) throw new Error(error.message)
  return data as FlightsByMonth[]
}

export async function getFlightsByWeekday(): Promise<FlightsByWeekday[]> {
  const supabase = createClient()

  const { data, error } = await supabase
    .schema('dws')
    .rpc('get_flights_by_weekday', {})

  if (error) throw new Error(error.message)
  return data as FlightsByWeekday[]
}

// Writes

function toFlightColumns(
  input: FlightUpsertInput,
): Omit<FlightsInsert, 'id' | 'user_id'> {
  return {
    airline_code: input.airlineCode,
    aircraft_type: input.aircraftType,
    dept_airport_iata: input.departureCode,
    arr_airport_iata: input.arrivalCode,
    departure_time: localToUtc(input.departureLocal, input.departureTz),
    arrival_time: localToUtc(input.arrivalLocal, input.arrivalTz),
    flight_number: input.flightNumber,
    ticket_class: input.ticketClass,
    seat_number: input.seatNumber,
    seat_position: input.seatPosition,
    tail_number: input.tailNumber,
  }
}

export async function addFlight(input: FlightUpsertInput) {
  const supabase = createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) throw new Error('Not authenticated')

  const { error } = await supabase
    .schema('dwd')
    .from('flights')
    .insert({ ...toFlightColumns(input), user_id: user.id })

  if (error) throw new Error(error.message)
}

export async function updateFlight(flightId: number, input: FlightUpsertInput) {
  const supabase = createClient()

  const { error } = await supabase
    .schema('dwd')
    .from('flights')
    .update(toFlightColumns(input))
    .eq('id', flightId)

  if (error) throw new Error(error.message)
}

export async function deleteFlight(flightId: number) {
  const supabase = createClient()

  const { error } = await supabase
    .schema('dwd')
    .from('flights')
    .delete()
    .eq('id', flightId)

  if (error) throw new Error(error.message)
}
