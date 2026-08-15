import StatusLabel from '@/components/status-label'
import { useLifetimeStats } from '@/features/flight/hooks/use-flight-map-data'
import StatsCarousel from '@/features/flight/ui/stats-carousel'

export default function StatsSection() {
  const { data: stats, error, isLoading } = useLifetimeStats()

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" description={error.message} />
  if (!stats) return null

  return <StatsCarousel stats={stats} />
}
