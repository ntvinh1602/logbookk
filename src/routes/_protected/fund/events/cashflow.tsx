import { useState, useMemo, useEffect, useRef } from 'react'
import { useQuery } from '@tanstack/react-query'
import { createFileRoute, useNavigate } from '@tanstack/react-router'
import { subMonths, startOfDay, endOfDay } from 'date-fns'
import {
  Calendar,
  Settings,
  Box,
  Banknote,
  HandCoins,
  Handshake,
  PiggyBank,
  Upload,
  TrendingUp,
  TrendingDown,
} from 'lucide-react'
import { events } from '@/features/fund/queries/events'
import { FilterToggleGroup } from '@/components/filter/toggle-options'
import {
  SelectAllEnabled,
  SingleOptionSelect,
} from '@/components/filter/select-options'
import { DateRangePicker } from '@/components/filter/date-picker'
import { FieldGroup } from '@/components/ui/field'
import { Separator } from '@/components/ui/separator'
import { CashflowTransactions } from '@/features/fund/components/events/cashflow-transactions'

export const Route = createFileRoute('/_protected/fund/events/cashflow')({
  component: CashflowEvents,
})

type Preset = '1M' | '3M' | '6M' | '1Y' | 'CUSTOM'

const presetOptions = [
  { key: '1M', label: 'Last 1 months' },
  { key: '3M', label: 'Last 3 months' },
  { key: '6M', label: 'Last 6 months' },
  { key: '1Y', label: 'Last 1 year' },
  { key: 'CUSTOM', label: 'Custom' },
] as const

const cashflowOperations = [
  { key: 'deposit', label: 'Deposit', icon: PiggyBank },
  { key: 'withdraw', label: 'Withdraw', icon: Upload },
  { key: 'income', label: 'Income', icon: TrendingUp },
  { key: 'expense', label: 'Expense', icon: TrendingDown },
]

const txCategory = [
  { key: 'stock', label: 'Stock', icon: Box },
  { key: 'cashflow', label: 'Cashflow', icon: Banknote },
  { key: 'borrow', label: 'Borrow', icon: HandCoins },
  { key: 'repay', label: 'Repay', icon: Handshake },
] as const

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

function CashflowEvents() {
  const navigate = useNavigate()

  const [preset, setPreset] = useState<Preset>('3M')
  const [customRange, setCustomRange] = useState<{
    startDate: Date
    endDate: Date
  }>(() => getDateRangeFromPreset('3M', new Date()))
  const [operation, setOperation] = useState<string>('all')

  const prevPresetRef = useRef(preset)
  useEffect(() => {
    if (preset === 'CUSTOM' && prevPresetRef.current !== 'CUSTOM') {
      setCustomRange(getDateRangeFromPreset(prevPresetRef.current, new Date()))
    }
    prevPresetRef.current = preset
  }, [preset])

  const dateRange = useMemo(() => {
    if (preset === 'CUSTOM') return customRange
    return getDateRangeFromPreset(preset, new Date())
  }, [preset, customRange])

  const startISO = useMemo(
    () => startOfDay(dateRange.startDate).toISOString(),
    [dateRange.startDate],
  )
  const endISO = useMemo(
    () => endOfDay(dateRange.endDate).toISOString(),
    [dateRange.endDate],
  )

  const { data, isPending, error } = useQuery(
    events.cashflowTx(
      startISO,
      endISO,
      operation === 'all' ? undefined : operation,
    ),
  )

  return (
    <div className="flex flex-col max-w-screen-lg mx-auto py-15 gap-8">
      <h1 className="text-2xl font-bold">Cashflow Events</h1>

      <FieldGroup className="gap-4">
        <div className="flex w-full flex-col gap-4 md:flex-row md:items-center">
          <div className="w-full min-w-0 overflow-hidden border-b border-muted md:flex-1">
            <FilterToggleGroup
              value="cashflow"
              onValueChange={(v) => {
                if (v) navigate({ to: `/fund/events/${v}` })
              }}
              options={txCategory}
            />
          </div>
          <div className="w-full flex-none md:w-auto md:pl-4">
            <SelectAllEnabled
              icon={Settings}
              placeholder="Operation"
              value={operation === 'all' ? null : operation}
              onValueChange={(v) => setOperation(v ?? 'all')}
              allLabel="All operations"
              options={cashflowOperations}
            />
          </div>
        </div>

        <div className="flex flex-col xl:flex-row gap-4 w-full">
          <Separator orientation="vertical" className="my-3 hidden xl:block" />
          <div className="flex flex-col md:flex-row w-full gap-4">
            <SingleOptionSelect
              icon={Calendar}
              placeholder="Preset"
              value={preset}
              onValueChange={(v) => setPreset(v as Preset)}
              options={presetOptions}
            />

            <DateRangePicker
              dateFrom={dateRange.startDate}
              dateTo={dateRange.endDate}
              onDateFromChange={(date) =>
                setCustomRange((prev) => ({ ...prev, startDate: date }))
              }
              onDateToChange={(date) =>
                setCustomRange((prev) => ({ ...prev, endDate: date }))
              }
              disabled={preset !== 'CUSTOM'}
            />
          </div>
        </div>
      </FieldGroup>

      <CashflowTransactions
        data={data ?? []}
        isLoading={isPending}
        error={error}
      />
    </div>
  )
}
