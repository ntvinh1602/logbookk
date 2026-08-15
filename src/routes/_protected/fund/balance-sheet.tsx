import StatusLabel from '@/components/status-label'
import BalanceSheet from '@/features/fund/components/balance-sheet'
import { useBalanceSheet } from '@/features/fund/hooks/use-dashboard-data'
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/_protected/fund/balance-sheet')({
  component: RouteComponent,
})

function RouteComponent() {
  const { data, error, isLoading } = useBalanceSheet()

  if (error) return <StatusLabel type="error" />
  if (isLoading || !data) return <StatusLabel type="loading" />

  const liability = data
    .filter((r) => r.asset_class === 'liability')
    .reduce((sum, r) => sum + r.total_value, 0)

  const equity = data
    .filter((r) => r.asset_class === 'equity')
    .reduce((sum, r) => sum + r.total_value, 0)

  return (
    <div className="flex flex-col max-w-screen-lg mx-auto py-15 gap-8">
      <h1 className="text-2xl font-bold">Balance Sheet</h1>

      <BalanceSheet bsData={data} liability={liability} equity={equity} />
    </div>
  )
}
