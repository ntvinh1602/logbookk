import { useQueries } from '@tanstack/react-query'
import { flights } from '@/features/flight/queries/flights'

export function useFlightFormOptions() {
  const [airlines, aircrafts, airports] = useQueries({
    queries: [flights.airlines(), flights.aircrafts(), flights.airports()],
  })

  return {
    airlineFormOptions: (airlines.data ?? []).map((a) => ({
      label: a.name,
      value: String(a.icao_code),
    })),
    aircraftFormOptions: (aircrafts.data ?? []).map((a) => ({
      label: a.model ? `${a.icao_code} — ${a.model}` : a.icao_code,
      value: String(a.icao_code),
    })),
    airportFormOptions: (airports.data ?? []).map((a) => ({
      label: `${a.iata_code} — ${a.name}`,
      value: String(a.iata_code),
    })),
  }
}
