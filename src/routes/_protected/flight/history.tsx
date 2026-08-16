import { AddFlightSection } from '@/features/flight/components/history/add-flight-section'
import { FlightsDataProvider } from '@/features/flight/components/history/flights-data-context'
import { FlightsFilterSection } from '@/features/flight/components/history/flights-filter-section'
import { FlightsListSection } from '@/features/flight/components/history/flights-list-section'
import { FlightsOptionsProvider } from '@/features/flight/components/history/flights-options-context'
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/_protected/flight/history')({
  component: RouteComponent,
})

function RouteComponent() {
  return (
    <FlightsOptionsProvider>
      <FlightsDataProvider>
        <div className="flex flex-col max-w-screen-lg mx-auto py-15 gap-8">
          <div className="flex justify-between">
            <h1 className="text-2xl font-bold">Flight History</h1>
            <AddFlightSection />
          </div>
          <FlightsFilterSection />
          <FlightsListSection />
        </div>
      </FlightsDataProvider>
    </FlightsOptionsProvider>
  )
}
