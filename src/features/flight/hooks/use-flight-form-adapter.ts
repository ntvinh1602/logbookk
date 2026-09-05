import { useCallback } from 'react'
import { formatInTimeZone } from 'date-fns-tz'
import type { FlightFormValues } from '@/features/flight/form/schema'
import type { FlightsSummaryRow } from '@/lib/supabase/api/types'

interface FormOptions {
  airlineFormOptions: { label: string; value: string }[]
  aircraftFormOptions: { label: string; value: string }[]
}

/**
 * Converts a flight (view row) into FlightFormValues (form model).
 *
 * Airport IATA codes and local times come straight off the view; airline (name
 * -> ICAO) and aircraft (model -> ICAO) need a reverse lookup because the view
 * only exposes their display labels.
 */
export function useFlightFormAdapter({
  airlineFormOptions,
  aircraftFormOptions,
}: FormOptions) {
  return useCallback(
    (flight: FlightsSummaryRow): Partial<FlightFormValues> => {
      const matchingAirline = airlineFormOptions.find(
        (opt) => opt.label === flight.airline_name,
      )
      const matchingAircraft = aircraftFormOptions.find((opt) => {
        const model = opt.label.split(' — ')[1]
        return Boolean(model) && model === flight.aircraft_type
      })

      return {
        departureCode: flight.departure_code ?? '',
        departureTimeLocal:
          flight.departure_time && flight.departure_tz
            ? formatInTimeZone(
                flight.departure_time,
                flight.departure_tz,
                "yyyy-MM-dd'T'HH:mm",
              )
            : '',
        arrivalCode: flight.arrival_code ?? '',
        arrivalTimeLocal:
          flight.arrival_time && flight.arrival_tz
            ? formatInTimeZone(
                flight.arrival_time,
                flight.arrival_tz,
                "yyyy-MM-dd'T'HH:mm",
              )
            : '',
        flightNumber: flight.flight_number ?? '',
        airlineCode: matchingAirline?.value ?? '',
        ticketClass: flight.ticket_class ?? 'eco',
        seatNo: flight.seat_number,
        seatPos: flight.seat_position,
        aircraftCode: matchingAircraft?.value ?? null,
        tailNo: flight.tail_number,
      }
    },
    [airlineFormOptions, aircraftFormOptions],
  )
}
