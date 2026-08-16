import { useQuery } from "@tanstack/react-query"
import { createContext, use, useMemo } from "react"
import { Spinner } from "@/components/ui/spinner"
import getAirlines from "@/features/flight/actions/get-airlines"
import type { Airline } from "@/features/flight/actions/get-airlines"
import getAircrafts from "@/features/flight/actions/get-aircrafts"
import type { Aircraft } from "@/features/flight/actions/get-aircrafts"
import getAirports from "@/features/flight/actions/get-airports"
import type { Airport } from "@/features/flight/actions/get-airports"

const FLIGHTS_START_YEAR = 2019

interface FlightsOptionsContextValue {
  airlineFilterOptions: { label: string; value: string }[]
  startYear: number
  airlineFormOptions: { label: string; value: string }[]
  aircraftFormOptions: { label: string; value: string }[]
  airportFormOptions: { label: string; value: string }[]
}

const FlightsOptionsContext =
  createContext<FlightsOptionsContextValue | null>(null)

export function FlightsOptionsProvider({
  children,
}: {
  children: React.ReactNode
}) {
  const airlines = useQuery<Airline[], Error>({
    queryKey: ["flight-airlines"],
    queryFn: () => getAirlines(),
    staleTime: Infinity,
  })
  const aircrafts = useQuery<Aircraft[], Error>({
    queryKey: ["flight-aircrafts"],
    queryFn: () => getAircrafts(),
    staleTime: Infinity,
  })
  const airports = useQuery<Airport[], Error>({
    queryKey: ["flight-airports"],
    queryFn: () => getAirports(),
    staleTime: Infinity,
  })

  const value = useMemo<FlightsOptionsContextValue>(
    () => ({
      // Filter options (value = name for text-based filtering on readable view)
      airlineFilterOptions: (airlines.data ?? []).map((a) => ({
        label: a.name,
        value: a.name,
      })),
      startYear: FLIGHTS_START_YEAR,
      // Form options (value = string id for form field compatibility)
      airlineFormOptions: (airlines.data ?? []).map((a) => ({
        label: a.name,
        value: String(a.id),
      })),
      aircraftFormOptions: (aircrafts.data ?? []).map((a) => ({
        label: a.model ? `${a.icao_code} — ${a.model}` : a.icao_code,
        value: String(a.id),
      })),
      airportFormOptions: (airports.data ?? []).map((a) => ({
        label: `${a.iata_code} — ${a.name}`,
        value: String(a.id),
      })),
    }),
    [airlines.data, aircrafts.data, airports.data],
  )

  const isLoading =
    airlines.isLoading || aircrafts.isLoading || airports.isLoading
  const error = airlines.error ?? aircrafts.error ?? airports.error

  if (isLoading) {
    return (
      <div className="flex justify-center py-32">
        <Spinner className="size-8" />
      </div>
    )
  }

  if (error) throw error

  return (
    <FlightsOptionsContext.Provider value={value}>
      {children}
    </FlightsOptionsContext.Provider>
  )
}

export function useFlightsOptions() {
  const ctx = use(FlightsOptionsContext)
  if (!ctx) {
    throw new Error(
      "useFlightsOptions must be used within FlightsOptionsProvider",
    )
  }
  return ctx
}
