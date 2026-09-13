import { useSelector } from '@tanstack/react-store'
import { ArrowDown, ArrowUp, ArrowUpDown } from 'lucide-react'
import type { CellData, Column, RowData, Table } from '@tanstack/react-table'
import { Button } from '@/components/ui/button'
import { cn } from "cn"
import type { DataTableFeatures } from './data-table-features'

interface DataTableColumnHeaderProps<
  TData extends RowData,
  TValue extends CellData,
> {
  column: Column<DataTableFeatures, TData, TValue>
  table: Table<DataTableFeatures, TData>
  label: string
}

/**
 * Sortable column header: label + indicator that cycles asc/desc/off.
 *
 * The sort direction is read by subscribing to the table's `sorting` slice
 * rather than calling `column.getIsSorted()` in render. This component's props
 * (`column`, `table`, `label`) are referentially stable across a sort, so under
 * React Compiler's auto-memoization a builder-method read would never be
 * invalidated and the arrow would stay stale. Subscribing makes the indicator a
 * real reactive dependency.
 */
export function DataTableColumnHeader<
  TData extends RowData,
  TValue extends CellData,
>({ column, table, label }: DataTableColumnHeaderProps<TData, TValue>) {
  const sorting = useSelector(table.store, (state) => state.sorting)
  const columnSort = sorting.find((s) => s.id === column.id)
  const sorted = columnSort ? (columnSort.desc ? 'desc' : 'asc') : false
  const Icon =
    sorted === 'asc' ? ArrowUp : sorted === 'desc' ? ArrowDown : ArrowUpDown

  return (
    <Button
      variant="ghost"
      onClick={column.getToggleSortingHandler()}
      className="hover:bg-transparent hover:text-primary px-0"
    >
      {label}
      <Icon
        aria-hidden
        className={cn(sorted === false && 'text-muted-foreground/50')}
      />
    </Button>
  )
}
