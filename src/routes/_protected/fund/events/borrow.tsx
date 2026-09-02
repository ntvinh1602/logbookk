import { useQuery } from '@tanstack/react-query'
import { createFileRoute, useNavigate } from '@tanstack/react-router'
import { Box, Banknote, HandCoins, Handshake } from 'lucide-react'
import { events } from '@/features/fund/queries/events'
import { FilterToggleGroup } from '@/components/filter/toggle-options'
import { FieldGroup } from '@/components/ui/field'
import { BorrowTransactions } from '@/features/fund/components/events/borrow-transactions'
import { BorrowForm } from '@/features/fund/form/borrowForm'

export const Route = createFileRoute('/_protected/fund/events/borrow')({
  component: BorrowEvents,
})

const txCategory = [
  { key: 'stock', label: 'Stock', icon: Box },
  { key: 'cashflow', label: 'Cashflow', icon: Banknote },
  { key: 'borrow', label: 'Borrow', icon: HandCoins },
  { key: 'repay', label: 'Repay', icon: Handshake },
] as const

function BorrowEvents() {
  const navigate = useNavigate()

  const { data, isPending, error } = useQuery(events.borrowTx())

  return (
    <div className="flex flex-col max-w-screen-lg mx-auto py-15 gap-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Borrow Events</h1>
        <BorrowForm />
      </div>

      <FieldGroup className="gap-4">
        <div className="flex w-full flex-col gap-4 md:flex-row md:items-center">
          <div className="w-full min-w-0 overflow-hidden border-b border-muted md:flex-1">
            <FilterToggleGroup
              value="borrow"
              onValueChange={(v) => {
                if (v) navigate({ to: `/fund/events/${v}` })
              }}
              options={txCategory}
            />
          </div>
        </div>
      </FieldGroup>

      <BorrowTransactions
        data={data ?? []}
        isLoading={isPending}
        error={error}
      />
    </div>
  )
}
