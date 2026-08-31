import { useQuery } from '@tanstack/react-query'
import { createFileRoute, useNavigate } from '@tanstack/react-router'
import { Box, Banknote, HandCoins, Handshake } from 'lucide-react'
import { events } from '@/features/fund/queries/events'
import { FilterToggleGroup } from '@/components/filter/toggle-options'
import { FieldGroup } from '@/components/ui/field'
import { RepayTransactions } from '@/features/fund/components/events/repay-transactions'

export const Route = createFileRoute('/_protected/fund/events/repay')({
  component: RepayEvents,
})

const txCategory = [
  { key: 'stock', label: 'Stock', icon: Box },
  { key: 'cashflow', label: 'Cashflow', icon: Banknote },
  { key: 'borrow', label: 'Borrow', icon: HandCoins },
  { key: 'repay', label: 'Repay', icon: Handshake },
] as const

function RepayEvents() {
  const navigate = useNavigate()

  const { data, isPending, error } = useQuery(events.repayTx())

  return (
    <div className="flex flex-col max-w-screen-lg mx-auto py-15 gap-8">
      <h1 className="text-2xl font-bold">Repay Events</h1>

      <FieldGroup className="gap-4">
        <div className="flex w-full flex-col gap-4 md:flex-row md:items-center">
          <div className="w-full min-w-0 overflow-hidden border-b border-muted md:flex-1">
            <FilterToggleGroup
              value="repay"
              onValueChange={(v) => {
                if (v) navigate({ to: `/fund/events/${v}` })
              }}
              options={txCategory}
            />
          </div>
        </div>
      </FieldGroup>

      <RepayTransactions
        data={data ?? []}
        isLoading={isPending}
        error={error}
      />
    </div>
  )
}
