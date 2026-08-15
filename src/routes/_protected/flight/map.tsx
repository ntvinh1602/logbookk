import StatsSection from '@/features/flight/components/map/stats-section'
import FlightMapSection from '@/features/flight/components/map/map-section'
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/_protected/flight/map')({
  component: RouteComponent,
})

function RouteComponent() {
  return (
    <div className="flex h-[calc(100dvh-3.5rem)] flex-col gap-8 pt-15">
      <div className="flex flex-col w-full max-w-screen-2xl mx-auto gap-8">
        <h1 className="text-2xl font-bold">Flight Map</h1>
        <StatsSection />
      </div>
      <FlightMapSection />
    </div>
  )
}
