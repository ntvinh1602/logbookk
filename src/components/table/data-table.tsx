import type { ColumnDef, RowData, SortingState } from '@tanstack/react-table'
import { useTable } from '@tanstack/react-table'
import {
  Table,
  TableBody,
  TableCell,
  TableFooter,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { cn } from '@/lib/utils'
import { DataTablePagination } from './data-table-pagination'
import type { DataTableFeatures } from './data-table-features'
import { dataTableFeatures } from './data-table-features'

interface DataTableProps<TData extends RowData> {
  columns: ColumnDef<DataTableFeatures, TData>[]
  data: TData[]
  getRowId?: (originalRow: TData, index: number) => string
  /** Initial column sort applied on mount (and on `resetSorting`). */
  initialSorting?: SortingState
}

const alignToClass = (align?: 'left' | 'right' | 'center') =>
  align === 'right'
    ? 'text-right'
    : align === 'center'
      ? 'text-center'
      : undefined

/** Headless rows/headers on top of the table primitives, with click-to-sort. */
export function DataTable<TData extends RowData>({
  columns,
  data,
  getRowId,
  initialSorting,
}: DataTableProps<TData>) {
  const table = useTable({
    features: dataTableFeatures,
    columns,
    data,
    getRowId,
    initialState: initialSorting ? { sorting: initialSorting } : undefined,
  })
  const columnCount = table.getAllLeafColumns().length
  const showPagination = table.getPageCount() > 1

  return (
    <Table>
      <TableHeader>
        {table.getHeaderGroups().map((group) => (
          <TableRow key={group.id}>
            {group.headers.map((header) => {
              if (header.isPlaceholder) return null
              const sorted = header.column.getIsSorted()
              return (
                <TableHead
                  key={header.id}
                  aria-sort={
                    sorted === 'asc'
                      ? 'ascending'
                      : sorted === 'desc'
                        ? 'descending'
                        : 'none'
                  }
                  className={cn(
                    alignToClass(header.column.columnDef.meta?.align),
                  )}
                >
                  <table.FlexRender header={header} />
                </TableHead>
              )
            })}
          </TableRow>
        ))}
      </TableHeader>
      <TableBody>
        {table.getRowModel().rows.map((row) => (
          <TableRow key={row.id}>
            {row.getAllCells().map((cell) => (
              <TableCell
                key={cell.id}
                className={cn(alignToClass(cell.column.columnDef.meta?.align))}
              >
                <table.FlexRender cell={cell} />
              </TableCell>
            ))}
          </TableRow>
        ))}
      </TableBody>
      {showPagination && (
        <TableFooter>
          <TableRow>
            <TableCell colSpan={columnCount} className="px-2 py-2">
              <DataTablePagination table={table} />
            </TableCell>
          </TableRow>
        </TableFooter>
      )}
    </Table>
  )
}
