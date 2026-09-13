import type { SortingState } from '@tanstack/react-table'
import { createColumnHelper } from '@tanstack/react-table'
import { formatInTimeZone } from 'date-fns-tz'
import StatusLabel from '@/components/status-label'
import { DataTable } from '@/components/table/data-table'
import { DataTableColumnHeader } from '@/components/table/data-table-column-header'
import type { DataTableFeatures } from '@/components/table/data-table-features'
import { Badge } from '@/components/ui/badge'
import type { FlightsSummaryRow } from '@/features/flight/types'
import { FlightItemMenu } from './flight-item-menu'
import { Item, ItemMedia, ItemTitle } from '@/components/ui/item'
import { formatNum } from '@/lib/utils'
import { Clock } from 'lucide-react'

interface HistoryBodyProps {
  data: FlightsSummaryRow[]
  isLoading: boolean
  error: Error | null
}

const INITIAL_SORTING: SortingState = [{ id: 'departure_time', desc: true }]

const columnHelper = createColumnHelper<DataTableFeatures, FlightsSummaryRow>()

const airlineLogo = (logo: string) =>
  `${import.meta.env.VITE_PUBLIC_SUPABASE_URL}/storage/v1/object/public/logo/airline/${logo}`

/** Airport badge + name, with the local time underneath. */
function Endpoint({
  code,
  name,
  time,
  tz,
}: {
  code: string
  name: string
  time: string
  tz: string
}) {
  return (
    <div className="flex flex-col gap-1 min-w-40">
      <span>{name}</span>
      <span className="text-xs text-muted-foreground gap-1 flex items-center">
        <Badge variant="outline" className="font-mono">
          {code}
        </Badge>
        <Badge variant="outline" className="font-mono">
          <Clock/>{formatInTimeZone(time, tz, 'HH:mm')}
        </Badge>
      </span>
    </div>
  )
}

export const columns = columnHelper.columns([
  columnHelper.accessor('departure_time', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Date" />
    ),
    cell: ({ row }) => (
      <span className="whitespace-nowrap">
        {formatInTimeZone(
          row.original.departure_time,
          row.original.departure_tz,
          'yyyy-MM-dd',
        )}
      </span>
    ),
  }),
  columnHelper.accessor('flight_number', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Flight" />
    ),
    cell: ({ row }) => {
      const flight = row.original
      const isUpcoming = new Date(flight.departure_time) > new Date()
      return (
        <Item size="xs" className="min-w-30">
          <ItemMedia>
            <img
              src={airlineLogo(flight.airline_logo)}
              className="rounded-sm"
            />
          </ItemMedia>
          <ItemTitle>
            {!isUpcoming ? (
              flight.flight_number
            ) : (
              <Badge variant="destructive">{flight.flight_number}</Badge>
            )}
          </ItemTitle>
        </Item>
      )
    },
  }),
  columnHelper.accessor('departure_name', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="From" />
    ),
    cell: ({ row }) => (
      <Endpoint
        code={row.original.departure_code}
        name={row.original.departure_name}
        time={row.original.departure_time}
        tz={row.original.departure_tz}
      />
    ),
  }),
  columnHelper.accessor('arrival_name', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="To" />
    ),
    cell: ({ row }) => (
      <Endpoint
        code={row.original.arrival_code}
        name={row.original.arrival_name}
        time={row.original.arrival_time}
        tz={row.original.arrival_tz}
      />
    ),
  }),
  columnHelper.accessor('distance_km', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Distance" />
    ),
    cell: ({ row }) => (
      <div className="flex flex-col items-start gap-1 whitespace-nowrap">
        <span>{formatNum(row.original.distance_km)} km</span>
        <span className="text-muted-foreground text-xs">
          {row.original.duration}
        </span>
      </div>
    ),
  }),
  columnHelper.accessor('aircraft_type', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Aircraft" />
    ),
    cell: ({ row }) => (
      <div className="flex flex-col items-start gap-1 whitespace-nowrap">
        <span>{row.original.aircraft_type}</span>
        {row.original.tail_number && (
          <span className="text-muted-foreground text-xs">
            {row.original.tail_number}
          </span>
        )}
      </div>
    ),
  }),
  columnHelper.display({
    id: 'actions',
    cell: ({ row }) => <FlightItemMenu flight={row.original} />,
    meta: { align: 'right' },
  }),
])

export function HistoryBody({ data, isLoading, error }: HistoryBodyProps) {
  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (data.length === 0) return <StatusLabel type="empty" />

  return (
    <DataTable
      columns={columns}
      data={data}
      getRowId={(row) => String(row.id)}
      initialSorting={INITIAL_SORTING}
      itemLabel="flights"
    />
  )
}
