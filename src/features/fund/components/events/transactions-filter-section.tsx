"use client"

import { useTransactionsData } from "./transactions-data-context"
import { TxFilter } from "@/features/fund/ui/tx-filter"

export function TransactionsFilterSection({
  onCategoryChange,
}: {
  onCategoryChange?: (category: string) => void
}) {
  const {
    state: { filters, preset, resolvedStartDate, resolvedEndDate },
    actions: {
      setFilters,
      setPreset,
      onCustomStartDateChange,
      onCustomEndDateChange,
    },
  } = useTransactionsData()

  return (
    <TxFilter
      filters={filters}
      onFiltersChange={setFilters}
      onCategoryChange={onCategoryChange}
      preset={preset}
      onPresetChange={setPreset}
      resolvedStartDate={resolvedStartDate}
      resolvedEndDate={resolvedEndDate}
      onCustomStartDateChange={onCustomStartDateChange}
      onCustomEndDateChange={onCustomEndDateChange}
    />
  )
}
