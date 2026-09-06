import { useState } from 'react'
import { Accordion } from '@/components/ui/accordion'
import { ItemGroup, ItemTitle } from '@/components/ui/item'
import StatusLabel from '@/components/status-label'
import type { FlightsSummaryRow } from '@/features/flight/types'
import { FlightItem } from './flight-item'
import { FlightItemMenu } from './flight-item-menu'

interface HistoryBodyProps {
  data: FlightsSummaryRow[]
  isLoading: boolean
  error: Error | null
}

export function HistoryBody({ data, isLoading, error }: HistoryBodyProps) {
  const [openKey, setOpenKey] = useState('')

  if (error) return <StatusLabel type="error" />
  if (isLoading && data.length === 0) return <StatusLabel type="loading" />
  if (data.length === 0) return <StatusLabel type="empty" />

  return (
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
  )
}
