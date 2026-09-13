import type { SortingState } from '@tanstack/react-table'
import StatusLabel from '@/components/status-label'
import { DataTable } from '@/components/table/data-table'
import { createColumnHelper } from '@tanstack/react-table'
import { format } from 'date-fns'
import { DataTableColumnHeader } from '@/components/table/data-table-column-header'
import type { DataTableFeatures } from '@/components/table/data-table-features'
import { Badge } from '@/components/ui/badge'
import { cn, formatNum } from '@/lib/utils'
import { EVENT_CATEGORY } from '@/features/fund/config'
import type { CashflowOps } from '@/features/fund/config'
import type { CashflowEvents } from '@/features/fund/types'

const INITIAL_SORTING: SortingState = [{ id: 'created_at', desc: true }]

interface Props {
  data: CashflowEvents[]
  isLoading: boolean
  error: Error | null
}
const OpsConfig = EVENT_CATEGORY.cashflow.operations

const columnHelper = createColumnHelper<DataTableFeatures, CashflowEvents>()

export const columns = columnHelper.columns([
  columnHelper.accessor('operation', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Operation" />
    ),
    cell: ({ getValue }) => {
      const operation = getValue()
      const op = OpsConfig[operation as CashflowOps]
      return (
        <Badge className={cn(op.color, 'capitalize rounded-sm')}>
          {operation}
        </Badge>
      )
    },
  }),
  columnHelper.accessor('memo', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Memo" />
    ),
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
  columnHelper.accessor('quantity', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Quantity" />
    ),
    // Cash-only rows carry no traded quantity, so they read as an explicit blank.
    cell: ({ row }) =>
      row.original.ticker === 'FX.VND' ? (
        <span className="text-muted-foreground">—</span>
      ) : (
        <span>{`${formatNum(row.original.quantity, 2)} ${row.original.currency}`}</span>
      ),
    meta: { align: 'right' },
  }),
  columnHelper.accessor('net_proceed', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Amount" />
    ),
    cell: ({ getValue }) => {
      return <span>{formatNum(getValue())}</span>
    },
    meta: { align: 'right' },
  }),
])

export function CashflowEventTable({ data, isLoading, error }: Props) {
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
