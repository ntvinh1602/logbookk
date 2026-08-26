import StatusLabel from '@/components/status-label'
import BalanceSheet from '@/features/fund/components/balance-sheet'
import { dashboard } from '@/features/fund/queries/dashboard'
import { useQuery } from '@tanstack/react-query'
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/_protected/fund/balance-sheet')({
  component: RouteComponent,
})

function RouteComponent() {
  const { data, error, isLoading } = useQuery(dashboard.balanceSheet())

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />
  if (!data) return null

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
