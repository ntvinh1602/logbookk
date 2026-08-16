import { useCallback } from "react"
import { formatInTimeZone } from "date-fns-tz"
import type { FlightFormValues } from "@/features/flight/form/schema"
import type { Flight } from "@/features/flight/ui/flight-config"

interface FormOptions {
  airlineFormOptions: { label: string; value: string }[]
  aircraftFormOptions: { label: string; value: string }[]
  airportFormOptions: { label: string; value: string }[]
}

/**
 * Converts a Flight (view model) into FlightFormValues (form model)
 * by reverse-mapping display labels back to database IDs.
 */
export function useFlightFormAdapter({
  airlineFormOptions,
  aircraftFormOptions,
  airportFormOptions,
}: FormOptions) {
  return useCallback(
    (flight: Flight): Partial<FlightFormValues> => {
      const matchingAirline = airlineFormOptions.find(
        (opt) => opt.label === flight.airline_name,
      )
      const matchingAircraft = aircraftFormOptions.find((opt) => {
        const model = opt.label.split(" — ")[1]
        return model && model === flight.aircraft_type
      })
      const matchingDeparture = airportFormOptions.find((opt) => {
        const name = opt.label.split(" — ")[1]
        return name === flight.departure_name
      })
      const matchingArrival = airportFormOptions.find((opt) => {
        const name = opt.label.split(" — ")[1]
        return name === flight.arrival_name
      })

      return {
        departureAirportId: matchingDeparture?.value ?? "",
        departureTimeLocal:
          flight.departure_time && flight.departure_tz
            ? formatInTimeZone(
                flight.departure_time,
                flight.departure_tz,
                "yyyy-MM-dd'T'HH:mm",
              )
            : "",
        arrivalAirportId: matchingArrival?.value ?? "",
        arrivalTimeLocal:
          flight.arrival_time && flight.arrival_tz
            ? formatInTimeZone(
                flight.arrival_time,
                flight.arrival_tz,
                "yyyy-MM-dd'T'HH:mm",
              )
            : "",
        flightNumber: flight.flight_number,
        airlineId: matchingAirline?.value ?? "",
        ticketClass: flight.ticket_class,
        seatNo: flight.seat_number,
        seatPos: flight.seat_position,
        aircraftId: matchingAircraft?.value ?? null,
        tailNo: flight.tail_number,
        notes: null,
      }
    },
    [airlineFormOptions, aircraftFormOptions, airportFormOptions],
  )
}
