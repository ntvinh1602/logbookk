import type { SortingState } from '@tanstack/react-table'
import StatusLabel from '@/components/status-label'
import { DataTable } from '@/components/table/data-table'
import { createColumnHelper } from '@tanstack/react-table'
import { format } from 'date-fns'
import { DataTableColumnHeader } from '@/components/table/data-table-column-header'
import type { DataTableFeatures } from '@/components/table/data-table-features'
import { Badge } from '@/components/ui/badge'
import { formatNum } from '@/lib/utils'
import { cn } from "cn"
import { EVENT_CATEGORY, type StockOps } from '@/features/fund/config'
import type { StockEvents } from '@/features/fund/types'

const INITIAL_SORTING: SortingState = [{ id: 'created_at', desc: true }]

interface Props {
  data: StockEvents[]
  isLoading: boolean
  error: Error | null
}
const OpsConfig = EVENT_CATEGORY.stock.operations

const columnHelper = createColumnHelper<DataTableFeatures, StockEvents>()

export const columns = columnHelper.columns([
  columnHelper.accessor('name', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Stock" />
    ),
    cell: ({ row }) => (
      <span className="inline-flex items-center gap-2">
        <Badge variant="secondary" className="font-mono">
          {row.original.ticker}
        </Badge>
        {row.original.name}
      </span>
    ),
  }),
  columnHelper.accessor('operation', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Operation" />
    ),
    cell: ({ getValue }) => {
      const operation = getValue()
      const op = OpsConfig[operation as StockOps]
      return (
        <Badge className={cn(op.color, 'capitalize rounded-sm')}>
          {operation}
        </Badge>
      )
    },
  }),
  columnHelper.accessor('created_at', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Time" />
    ),
    cell: ({ row }) => {
      const date = new Date(row.original.created_at)
      return (
        <span className="whitespace-nowrap">
          {format(date, 'yyyy-MM-dd HH:mm')}
        </span>
      )
    },
  }),
  columnHelper.accessor('fee', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Fee" />
    ),
    cell: ({ getValue }) => {
      return <span>{formatNum(getValue())}</span>
    },
    meta: { align: 'right' },
  }),
  columnHelper.accessor('tax', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Tax" />
    ),
    cell: ({ getValue }) => {
      return <span>{formatNum(getValue())}</span>
    },
    meta: { align: 'right' },
  }),
  columnHelper.accessor('net_proceed', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Value" />
    ),
    cell: ({ getValue }) => {
      return <span>{formatNum(getValue())}</span>
    },
    meta: { align: 'right' },
  }),
])

export function StockEventTable({ data, isLoading, error }: Props) {
  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (data.length === 0) return <StatusLabel type="empty" />

  return (
    <DataTable
      columns={columns}
      data={data}
      getRowId={(row) => String(row.tx_id)}
      initialSorting={INITIAL_SORTING}
    />
  )
}
