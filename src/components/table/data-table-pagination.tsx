import { ChevronLeft, ChevronRight } from 'lucide-react'
import type { ReactTable, RowData } from '@tanstack/react-table'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import type { DataTableFeatures } from './data-table-features'

const PAGE_SIZES = [10, 20, 50]

interface DataTablePaginationProps<TData extends RowData> {
  table: ReactTable<DataTableFeatures, TData>
}

/** Paged footer: rows info, rows-per-page selector, and Previous/Next. */
export function DataTablePagination<TData extends RowData>({
  table,
}: DataTablePaginationProps<TData>) {
  const { pageIndex, pageSize } = table.state.pagination
  const total = table.getPrePaginatedRowModel().rows.length
  const from = total === 0 ? 0 : pageIndex * pageSize + 1
  const to = Math.min(total, (pageIndex + 1) * pageSize)

  return (
    <div className="flex flex-wrap items-center justify-between gap-3">
      <p className="text-sm text-muted-foreground">
        Showing <span className="text-foreground">{from}</span>-
        <span className="text-foreground">{to}</span> of{' '}
        <span className="text-foreground">{total}</span>
      </p>

      <div className="flex flex-wrap items-center gap-3">
        <Select
          value={String(pageSize)}
          onValueChange={(value) => table.setPageSize(Number(value))}
        >
          <SelectTrigger className="h-8 w-24" aria-label="Rows per page">
            <SelectValue />
          </SelectTrigger>
          <SelectContent align="end">
            {PAGE_SIZES.map((size) => (
              <SelectItem key={size} value={String(size)}>
                {size} / page
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="sm"
            disabled={!table.getCanPreviousPage()}
            onClick={() => table.previousPage()}
          >
            <ChevronLeft
              aria-hidden
              className="size-4"
              data-icon="inline-start"
            />
            Previous
          </Button>
          <Button
            variant="ghost"
            size="sm"
            disabled={!table.getCanNextPage()}
            onClick={() => table.nextPage()}
          >
            Next
            <ChevronRight
              aria-hidden
              className="size-4"
              data-icon="inline-end"
            />
          </Button>
        </div>
      </div>
    </div>
  )
}
