import {
  createPaginatedRowModel,
  createSortedRowModel,
  rowPaginationFeature,
  rowSortingFeature,
  tableFeatures,
} from '@tanstack/react-table'
import type { CellData, RowData, TableFeatures } from '@tanstack/react-table'

// Allow column defs to opt into alignment via `meta: { align: 'right' }`, which
// DataTable applies to the header and cells.
declare module '@tanstack/table-core' {
  interface ColumnMeta<
    TFeatures extends TableFeatures,
    TData extends RowData,
    TValue extends CellData = CellData,
  > {
    align?: 'left' | 'right' | 'center'
  }
}

/**
 * The feature set shared by every app table. Register new optional features
 * here (e.g. filtering, column visibility) and column/table types pick them up
 * through {@link DataTableFeatures}.
 */
export const dataTableFeatures = tableFeatures({
  rowSortingFeature,
  sortedRowModel: createSortedRowModel(),
  rowPaginationFeature,
  paginatedRowModel: createPaginatedRowModel(),
})

export type DataTableFeatures = typeof dataTableFeatures
