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

/** Rows per page a table starts on, until the user picks another size. */
export const DEFAULT_PAGE_SIZE = 20

interface DataTablePaginationProps<TData extends RowData> {
  table: ReactTable<DataTableFeatures, TData>
  /** Noun for the total-rows label, e.g. `flights` -> "Found 42 flights". */
  itemLabel?: string
}

/** Paged footer: rows info, rows-per-page selector, and Previous/Next. */
export function DataTablePagination<TData extends RowData>({
  table,
  itemLabel = 'events',
}: DataTablePaginationProps<TData>) {
  const { pageIndex, pageSize } = table.state.pagination
  const total = table.getPrePaginatedRowModel().rows.length
  const totalPages = Math.ceil(total / pageSize)

  return (
    <div className="flex w-full items-center justify-between gap-3 px-2">
      <span className="text-sm text-muted-foreground">
        {`Found ${total} ${itemLabel}`}
      </span>

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
            variant="outline"
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
          <span className="text-sm text-muted-foreground px-4">
            {`${pageIndex + 1} of ${totalPages}`}
          </span>
          <Button
            variant="outline"
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
