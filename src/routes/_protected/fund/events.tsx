import { AddEventProvider } from '@/features/fund/components/events/add-event-context'
import { AddEventSection } from '@/features/fund/components/events/add-event-section'
import { TransactionsDataProvider } from '@/features/fund/components/events/transactions-data-context'
import { TransactionsFilterSection } from '@/features/fund/components/events/transactions-filter-section'
import { TransactionsListSection } from '@/features/fund/components/events/transactions-list-section'
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/_protected/fund/events')({
  component: RouteComponent,
})

function RouteComponent() {
  return (
    <AddEventProvider>
      <TransactionsDataProvider>
        <div className="flex flex-col max-w-screen-lg mx-auto py-15 gap-8">
          <div className="flex justify-between">
            <h1 className="text-2xl font-bold">Events History</h1>
            <AddEventSection />
          </div>
          <div className="flex flex-col w-full gap-8">
            <TransactionsFilterSection />
            <TransactionsListSection />
          </div>
        </div>
      </TransactionsDataProvider>
    </AddEventProvider>
  )
}
