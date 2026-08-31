"use client"

import { createContext, use, useMemo } from "react"
import { useQuery, useQueryClient } from "@tanstack/react-query"
import { startOfDay, endOfDay } from "date-fns"
import { useTransactionFilters } from "@/features/fund/hooks/use-transaction-filters"
import { events } from "@/features/fund/queries/events"
import type { EventStock } from "@/features/fund/fund.types"

interface TransactionsDataContextValue {
  state: {
    data: EventStock[]
    isSuccess: boolean
    isLoading: boolean
    isFetching: boolean
    error: Error | null
    filters: ReturnType<typeof useTransactionFilters>["filters"]
    preset: ReturnType<typeof useTransactionFilters>["preset"]
    resolvedStartDate: Date
    resolvedEndDate: Date
  }
  actions: {
    setFilters: ReturnType<typeof useTransactionFilters>["setFilters"]
    setPreset: ReturnType<typeof useTransactionFilters>["setPreset"]
    onCustomStartDateChange: (date: Date | undefined) => void
    onCustomEndDateChange: (date: Date | undefined) => void
    triggerRefresh: () => void
  }
}

const TransactionsDataContext = createContext<TransactionsDataContextValue | null>(
  null,
)

export function TransactionsDataProvider({
  children,
  initialCategory,
}: {
  children: React.ReactNode
  initialCategory?: string
}) {
  const queryClient = useQueryClient()

  const {
    preset,
    setPreset,
    resolvedStartDate,
    resolvedEndDate,
    onCustomStartDateChange,
    onCustomEndDateChange,
    filters,
    setFilters,
  } = useTransactionFilters({ initialCategory })

  const startDate = useMemo(
    () => startOfDay(resolvedStartDate).toISOString(),
    [resolvedStartDate],
  )
  const endDate = useMemo(
    () => endOfDay(resolvedEndDate).toISOString(),
    [resolvedEndDate],
  )

  const {
    data: transactions,
    isSuccess,
    isLoading,
    isFetching,
    error,
  } = useQuery(events.stockTx(startDate, endDate))

  const triggerRefresh = useMemo(() => {
    return () => {
      queryClient.invalidateQueries({ queryKey: events.stockTx(startDate, endDate).queryKey })
    }
  }, [queryClient, startDate, endDate])

  return (
    <TransactionsDataContext.Provider
      value={{
        state: {
          data: transactions ?? [],
          isSuccess,
          isLoading,
          isFetching,
          error,
          filters,
          preset,
          resolvedStartDate,
          resolvedEndDate,
        },
        actions: {
          setFilters,
          setPreset,
          onCustomStartDateChange,
          onCustomEndDateChange,
          triggerRefresh,
        },
      }}
    >
      {children}
    </TransactionsDataContext.Provider>
  )
}

export function useTransactionsData() {
  const ctx = use(TransactionsDataContext)
  if (!ctx) {
    throw new Error(
      "useTransactionsData must be used within TransactionsDataProvider",
    )
  }
  return ctx
}
