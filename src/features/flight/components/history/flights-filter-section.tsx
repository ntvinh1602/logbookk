"use client"

import { useFlightsData } from "./flights-data-context"
import { useFlightsOptions } from "./flights-options-context"
import { FlightFilter } from "@/features/flight/ui/flight-filter"

export function FlightsFilterSection() {
  const {
    state: { filters },
    actions: { setFilters },
  } = useFlightsData()
  const { airlineFilterOptions, startYear } = useFlightsOptions()

  return (
    <FlightFilter
      filters={filters}
      onFiltersChange={setFilters}
      airlineOptions={airlineFilterOptions}
      startYear={startYear}
    />
  )
}
