import type { ComponentType } from 'react'
import { useQuery } from '@tanstack/react-query'
import { getRouteApi } from '@tanstack/react-router'
import { events } from '@/features/fund/queries/events'
import { EVENT_CATEGORY } from '@/features/fund/config'
import type { Events } from '@/features/fund/config'
import { getValidOp } from '@/features/fund/utils'
import { useEventDateRange } from '@/features/fund/hooks/use-event-date-range'
import { StockTransactions } from './stock-transactions'
import { CashflowTransactions } from './cashflow-transactions'
import { BorrowTransactions } from './borrow-transactions'
import { RepayTransactions } from './repay-transactions'

const routeApi = getRouteApi('/_protected/fund/events/$event')

/* ---------- per-event lists (each runs its own typed query) ---------- */

function StockList() {
  const search = routeApi.useSearch()
  const { startISO, endISO } = useEventDateRange(search)
  const op = getValidOp(EVENT_CATEGORY.stock.operations, search.op)
  const query = useQuery(events.stockTx(startISO, endISO, undefined, op))

  return (
    <StockTransactions
      data={query.data ?? []}
      isLoading={query.isPending}
      error={query.error}
    />
  )
}

function CashflowList() {
  const search = routeApi.useSearch()
  const { startISO, endISO } = useEventDateRange(search)
  const op = getValidOp(EVENT_CATEGORY.cashflow.operations, search.op)
  const query = useQuery(events.cashflowTx(startISO, endISO, op))

  return (
    <CashflowTransactions
      data={query.data ?? []}
      isLoading={query.isPending}
      error={query.error}
    />
  )
}

function BorrowList() {
  const query = useQuery(events.borrowTx())

  return (
    <BorrowTransactions
      data={query.data ?? []}
      isLoading={query.isPending}
      error={query.error}
    />
  )
}

function RepayList() {
  const query = useQuery(events.repayTx())

  return (
    <RepayTransactions
      data={query.data ?? []}
      isLoading={query.isPending}
      error={query.error}
    />
  )
}

const EVENT_BODIES = {
  stock: StockList,
  cashflow: CashflowList,
  borrow: BorrowList,
  repay: RepayList,
} satisfies Record<Events, ComponentType>

export function EventBody({ event }: { event: Events }) {
  const Body = EVENT_BODIES[event]
  return <Body />
}
