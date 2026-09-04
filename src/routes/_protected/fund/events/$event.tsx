import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { createFileRoute, notFound, useNavigate } from '@tanstack/react-router'
import { endOfDay, format, parse, startOfDay, subMonths } from 'date-fns'
import {
  Banknote,
  Box,
  Calendar,
  Coins,
  HandCoins,
  Handshake,
  PiggyBank,
  Settings,
  ShoppingBag,
  TrendingDown,
  TrendingUp,
  Upload,
} from 'lucide-react'
import { events } from '@/features/fund/queries/events'
import { FilterToggleGroup } from '@/components/filter/toggle-options'
import {
  SelectAllEnabled,
  SingleOptionSelect,
} from '@/components/filter/select-options'
import { DateRangePicker } from '@/components/filter/date-picker'
import { FieldGroup } from '@/components/ui/field'
import { StockTransactions } from '@/features/fund/components/events/stock-transactions'
import { CashflowTransactions } from '@/features/fund/components/events/cashflow-transactions'
import { BorrowTransactions } from '@/features/fund/components/events/borrow-transactions'
import { RepayTransactions } from '@/features/fund/components/events/repay-transactions'
import { StockForm } from '@/features/fund/form/stockForm'
import { CashflowForm } from '@/features/fund/form/cashflowForm'
import { BorrowForm } from '@/features/fund/form/borrowForm'
import { RepayForm } from '@/features/fund/form/repayForm'

/* ---------- search schema (filter state lives in the URL) ---------- */

const PRESETS = ['1M', '3M', '6M', '1Y', 'CUSTOM'] as const
type Preset = (typeof PRESETS)[number]

function isPreset(value: unknown): value is Preset {
  return typeof value === 'string' && (PRESETS as readonly string[]).includes(value)
}

interface EventsSearch {
  preset?: Preset
  /** yyyy-MM-dd keys, meaningful only when preset === 'CUSTOM'. */
  from?: string
  to?: string
  /** Validated against the active event's operations before querying. */
  op?: string
}

const DATE_KEY_RE = /^\d{4}-\d{2}-\d{2}$/

function normalizeDateKey(value: unknown): string | undefined {
  return typeof value === 'string' && DATE_KEY_RE.test(value) ? value : undefined
}

function validateSearch(input: Record<string, unknown>): EventsSearch {
  return {
    preset: isPreset(input.preset) ? input.preset : '3M',
    from: normalizeDateKey(input.from),
    to: normalizeDateKey(input.to),
    op: typeof input.op === 'string' ? input.op : undefined,
  }
}

export const Route = createFileRoute('/_protected/fund/events/$event')({
  validateSearch,
  component: EventsPage,
})

/* ---------- event domain config ---------- */

type EventKey = 'stock' | 'cashflow' | 'borrow' | 'repay'

function isEventKey(value: unknown): value is EventKey {
  return value === 'stock' || value === 'cashflow' || value === 'borrow' || value === 'repay'
}

function isDatefulEvent(value: EventKey): value is 'stock' | 'cashflow' {
  return value === 'stock' || value === 'cashflow'
}

const eventTitles: Record<EventKey, string> = {
  stock: 'Stock Events',
  cashflow: 'Cashflow Events',
  borrow: 'Borrow Events',
  repay: 'Repay Events',
}

const txCategory = [
  { key: 'stock', label: 'Stock', icon: Box },
  { key: 'cashflow', label: 'Cashflow', icon: Banknote },
  { key: 'borrow', label: 'Borrow', icon: HandCoins },
  { key: 'repay', label: 'Repay', icon: Handshake },
] as const

const stockOperations = [
  { key: 'buy', label: 'Buy', icon: ShoppingBag },
  { key: 'sell', label: 'Sell', icon: Coins },
] as const

const cashflowOperations = [
  { key: 'deposit', label: 'Deposit', icon: PiggyBank },
  { key: 'withdraw', label: 'Withdraw', icon: Upload },
  { key: 'income', label: 'Income', icon: TrendingUp },
  { key: 'expense', label: 'Expense', icon: TrendingDown },
] as const

const presetOptions = [
  { key: '1M', label: 'Last 1 months' },
  { key: '3M', label: 'Last 3 months' },
  { key: '6M', label: 'Last 6 months' },
  { key: '1Y', label: 'Last 1 year' },
  { key: 'CUSTOM', label: 'Custom' },
] as const

/* ---------- date-range helpers ---------- */

const DATE_KEY = 'yyyy-MM-dd'

function toDateKey(date: Date) {
  return format(date, DATE_KEY)
}

function parseDateKey(value: string): Date {
  const date = parse(value, DATE_KEY, new Date())
  return Number.isNaN(date.getTime()) ? new Date() : date
}

function getDateRangeFromPreset(preset: Preset, now: Date) {
  switch (preset) {
    case '1M':
      return { startDate: subMonths(now, 1), endDate: now }
    case '3M':
      return { startDate: subMonths(now, 3), endDate: now }
    case '6M':
      return { startDate: subMonths(now, 6), endDate: now }
    case '1Y':
      return { startDate: subMonths(now, 12), endDate: now }
    default:
      return { startDate: subMonths(now, 3), endDate: now }
  }
}

/**
 * Derives the effective date window from the URL search. Presets compute a
 * rolling range relative to now; CUSTOM uses the from/to date keys. Returns
 * Date objects for the picker plus ISO bounds for the RPC query args.
 */
function useRangeFromSearch() {
  const { preset, from, to } = Route.useSearch()
  return useMemo(() => {
    if (preset !== 'CUSTOM') {
      const { startDate, endDate } = getDateRangeFromPreset(
        preset ?? '3M',
        new Date(),
      )
      return {
        displayFrom: startDate,
        displayTo: endDate,
        startISO: startOfDay(startDate).toISOString(),
        endISO: endOfDay(endDate).toISOString(),
      }
    }
    const fallback = getDateRangeFromPreset('3M', new Date())
    const fromDate = from ? parseDateKey(from) : fallback.startDate
    const toDate = to ? parseDateKey(to) : fallback.endDate
    return {
      displayFrom: fromDate,
      displayTo: toDate,
      startISO: startOfDay(fromDate).toISOString(),
      endISO: endOfDay(toDate).toISOString(),
    }
  }, [preset, from, to])
}

/** A URL op only counts if it is one of the active event's operations. */
function effectiveOp(
  op: string | undefined,
  ops: readonly { key: string }[],
): string | undefined {
  return op && ops.some((o) => o.key === op) ? op : undefined
}

/* ---------- page shell ---------- */

function EventsPage() {
  const { event } = Route.useParams()
  const navigate = useNavigate()

  if (!isEventKey(event)) throw notFound()

  return (
    <div className="flex flex-col max-w-screen-lg mx-auto py-15 gap-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{eventTitles[event]}</h1>
        <AddEventForm event={event} />
      </div>

      <FieldGroup className="gap-4">
        <div className="flex w-full flex-col gap-4 md:flex-row md:items-center">
          <div className="w-full min-w-0 overflow-hidden border-b border-muted md:flex-1">
            <FilterToggleGroup
              value={event}
              onValueChange={(v) => {
                // Switching category resets the filters to their defaults.
                if (v && v !== event && isEventKey(v)) {
                  navigate({
                    to: '/fund/events/$event',
                    params: { event: v },
                    search: {
                      preset: '3M',
                      from: undefined,
                      to: undefined,
                      op: undefined,
                    },
                  })
                }
              }}
              options={txCategory}
            />
          </div>
        </div>

        {isDatefulEvent(event) && <FilterBar event={event} />}
      </FieldGroup>

      <EventBody event={event} />
    </div>
  )
}

function AddEventForm({ event }: { event: EventKey }) {
  switch (event) {
    case 'stock':
      return <StockForm />
    case 'cashflow':
      return <CashflowForm />
    case 'borrow':
      return <BorrowForm />
    case 'repay':
      return <RepayForm />
    default:
      return null
  }
}

function EventBody({ event }: { event: EventKey }) {
  switch (event) {
    case 'stock':
      return <StockList />
    case 'cashflow':
      return <CashflowList />
    case 'borrow':
      return <BorrowList />
    case 'repay':
      return <RepayList />
    default:
      return null
  }
}

/* ---------- per-event lists (each runs its own typed query) ---------- */

function StockList() {
  const search = Route.useSearch()
  const { startISO, endISO } = useRangeFromSearch()
  const op = effectiveOp(search.op, stockOperations)

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
  const search = Route.useSearch()
  const { startISO, endISO } = useRangeFromSearch()
  const op = effectiveOp(search.op, cashflowOperations)

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

/* ---------- shared filter bar (stock & cashflow only) ---------- */

function FilterBar({ event }: { event: 'stock' | 'cashflow' }) {
  const navigate = useNavigate()
  const search = Route.useSearch()
  const preset = search.preset ?? '3M'
  const range = useRangeFromSearch()
  const ops = event === 'stock' ? stockOperations : cashflowOperations
  const currentOp = effectiveOp(search.op, ops)
  const isCustom = preset === 'CUSTOM'

  // Always submits the full search object so stale keys from a previous state
  // are replaced (explicit undefined clears a key under TanStack's merge).
  const go = (patch: Partial<EventsSearch>) =>
    navigate({
      to: '/fund/events/$event',
      params: { event },
      search: {
        preset,
        from: isCustom ? search.from : undefined,
        to: isCustom ? search.to : undefined,
        op: currentOp,
        ...patch,
      },
    })

  const handlePresetChange = (value: string) => {
    const next = isPreset(value) ? value : '3M'
    if (next === 'CUSTOM') {
      // Seed the custom range from the currently displayed preset range so the
      // picker opens exactly where the user was before entering CUSTOM.
      go({
        preset: 'CUSTOM',
        from: toDateKey(range.displayFrom),
        to: toDateKey(range.displayTo),
      })
    } else {
      go({ preset: next, from: undefined, to: undefined })
    }
  }

  return (
    <div className="flex flex-col xl:flex-row gap-3 w-full">
      <div className="w-full flex-none md:w-auto">
        <SelectAllEnabled
          icon={Settings}
          placeholder="Operation"
          value={currentOp ?? null}
          onValueChange={(v) => go({ op: v ?? undefined })}
          allLabel="All operations"
          options={ops}
        />
      </div>
      <div className="flex flex-col md:flex-row w-full gap-3">
        <SingleOptionSelect
          icon={Calendar}
          placeholder="Preset"
          value={preset}
          onValueChange={handlePresetChange}
          options={presetOptions}
        />

        <DateRangePicker
          dateFrom={range.displayFrom}
          dateTo={range.displayTo}
          onDateFromChange={(date) => go({ from: toDateKey(date) })}
          onDateToChange={(date) => go({ to: toDateKey(date) })}
          disabled={!isCustom}
        />
      </div>
    </div>
  )
}
