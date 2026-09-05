import { useState } from 'react'
import { useQueries } from '@tanstack/react-query'
import { createFileRoute, useNavigate } from '@tanstack/react-router'
import { Users, Calendar } from 'lucide-react'
import { flights } from '@/features/flight/queries/flights'
import { AddFlightForm } from '@/features/flight/form/flightsForm'
import {
  FlightItem,
  ticketClass,
} from '@/features/flight/components/history/flight-item'
import { FlightItemMenu } from '@/features/flight/components/history/flight-item-menu'
import { Accordion } from '@/components/ui/accordion'
import { ItemGroup, ItemTitle } from '@/components/ui/item'
import StatusLabel from '@/components/status-label'
import { SelectAllEnabled } from '@/components/filter/select-options'
import { FilterToggleGroup } from '@/components/filter/toggle-options'
import { FilterSearch } from '@/components/filter/text-search'
import { FieldGroup } from '@/components/ui/field'
import { Separator } from '@/components/ui/separator'

import type { FilterState } from '@/features/flight/flight.types'
import type { TicketClass } from '@/lib/supabase/api/types'

const TICKET_CLASSES = ['eco', 'biz'] as const
const FLIGHTS_START_YEAR = 2019

function isTicketClass(value: unknown): value is TicketClass {
  return (
    typeof value === 'string' &&
    (TICKET_CLASSES as readonly string[]).includes(value)
  )
}

interface FlightHistorySearch {
  year?: string | null
  airline?: string | null
  ticketClass?: TicketClass
  search?: string
}

function validateSearch(input: Record<string, unknown>): FlightHistorySearch {
  return {
    year: typeof input.year === 'string' ? input.year : null,
    airline: typeof input.airline === 'string' ? input.airline : null,
    ticketClass: isTicketClass(input.ticketClass) ? input.ticketClass : 'eco',
    search: typeof input.search === 'string' ? input.search : '',
  }
}

export const Route = createFileRoute('/_protected/flight/history')({
  validateSearch,
  component: RouteComponent,
})

function RouteComponent() {
  const search = Route.useSearch()
  const navigate = useNavigate()

  const [openKey, setOpenKey] = useState('')

  const [query, airlinesQuery] = useQueries({
    queries: [
      flights.list({
        year: search.year,
        airline: search.airline,
        ticketClass: search.ticketClass,
        search: search.search,
      }),
      flights.airlines(),
    ],
  })

  const data = query.data ?? []

  const airlineFilterOptions = (airlinesQuery.data ?? []).map((a) => ({
    key: a.name,
    label: a.name,
  }))

  const yearOptions = Array.from(
    { length: new Date().getFullYear() - FLIGHTS_START_YEAR + 1 },
    (_, i) => ({
      key: (FLIGHTS_START_YEAR + i).toString(),
      label: (FLIGHTS_START_YEAR + i).toString(),
    }),
  ).reverse()

  const filters: FilterState = {
    year: search.year ?? null,
    airline: search.airline ?? null,
    ticketClass: search.ticketClass ?? 'eco',
    search: search.search ?? '',
  }

  const setFilter = <TKey extends keyof FilterState>(
    key: TKey,
    value: FilterState[TKey],
  ) => {
    navigate({
      to: '/flight/history',
      search: { ...filters, [key]: value },
    })
  }

  return (
    <div className="flex flex-col max-w-screen-lg mx-auto py-15 gap-8">
      <div className="flex justify-between">
        <h1 className="text-2xl font-bold">Flight History</h1>
        <AddFlightForm />
      </div>
      <FieldGroup className="gap-4">
        <div className="w-full min-w-0 overflow-hidden border-b border-muted md:flex-1">
          <FilterToggleGroup
            value={filters.ticketClass}
            onValueChange={(v) => {
              if (v) setFilter('ticketClass', v as FilterState['ticketClass'])
            }}
            options={ticketClass}
          />
        </div>

        <div className="flex flex-col xl:flex-row gap-4 w-full">
          <FilterSearch
            placeholder="Flight number"
            value={filters.search}
            onCommit={(v) => setFilter('search', v)}
          />

          <Separator orientation="vertical" className="my-3 hidden xl:block" />

          <SelectAllEnabled
            icon={Users}
            placeholder="Airline"
            value={filters.airline}
            onValueChange={(v) => setFilter('airline', v)}
            allLabel="All Airlines"
            options={airlineFilterOptions}
          />

          <Separator orientation="vertical" className="my-3 hidden xl:block" />

          <SelectAllEnabled
            icon={Calendar}
            placeholder="Year"
            value={filters.year}
            onValueChange={(v) => setFilter('year', v)}
            allLabel="All Years"
            options={yearOptions}
          />
        </div>
      </FieldGroup>
      {query.error ? (
        <StatusLabel type="error" />
      ) : query.isPending && data.length === 0 ? (
        <StatusLabel type="loading" />
      ) : data.length === 0 ? (
        <StatusLabel type="empty" />
      ) : (
        <ItemGroup>
          <ItemTitle>Found {data.length} flights</ItemTitle>
          <Accordion
            multiple={false}
            value={openKey ? [openKey] : []}
            onValueChange={(value) => setOpenKey(value[0] ?? '')}
          >
            {data.map((flight) => {
              const itemKey = String(flight.id)

              return (
                <FlightItem
                  key={itemKey}
                  flight={flight}
                  itemKey={itemKey}
                  menuSlot={<FlightItemMenu flight={flight} />}
                />
              )
            })}
          </Accordion>
        </ItemGroup>
      )}
    </div>
  )
}
