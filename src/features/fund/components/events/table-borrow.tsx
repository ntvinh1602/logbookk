import type { SortingState } from '@tanstack/react-table'
import StatusLabel from '@/components/status-label'
import { DataTable } from '@/components/table/data-table'
import { createColumnHelper } from '@tanstack/react-table'
import { format } from 'date-fns'
import { DataTableColumnHeader } from '@/components/table/data-table-column-header'
import type { DataTableFeatures } from '@/components/table/data-table-features'
import { formatNum } from '@/lib/utils'
import type { BorrowEvents } from '@/features/fund/types'

const INITIAL_SORTING: SortingState = [{ id: 'created_at', desc: true }]

interface Props {
  data: BorrowEvents[]
  isLoading: boolean
  error: Error | null
}

const columnHelper = createColumnHelper<DataTableFeatures, BorrowEvents>()

export const columns = columnHelper.columns([
  columnHelper.accessor('lender', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Lender" />
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
  columnHelper.accessor('rate', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Rate" />
    ),
    cell: ({ getValue }) => {
      return <span>{formatNum(getValue(), 2)}%</span>
    },
    meta: { align: 'right' },
  }),
  columnHelper.accessor('principal', {
    header: ({ column, table }) => (
      <DataTableColumnHeader column={column} table={table} label="Amount" />
    ),
    cell: ({ getValue }) => {
      return <span>{formatNum(getValue())}</span>
    },
    meta: { align: 'right' },
  }),
])

export function BorrowEventTable({ data, isLoading, error }: Props) {
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
