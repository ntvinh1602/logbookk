import StatsSection from '@/features/flight/components/map/stats-section'
import FlightMapSection from '@/features/flight/components/map/map-section'
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/_protected/flight/map')({
  component: RouteComponent,
})

function RouteComponent() {
  return (
    <div className="flex h-200 flex-col gap-8">
      <FlightMapSection />
      <div className="flex flex-col w-full max-w-screen-2xl mx-auto gap-8">
        <StatsSection />
      </div>
    </div>
  )
}
