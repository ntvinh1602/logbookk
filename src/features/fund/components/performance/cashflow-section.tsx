import { useMemo } from 'react'
import { usePerformanceYear } from './year-context'
import { useCashflow } from '@/features/fund/hooks/use-performance-data'
import StatusLabel from '@/components/status-label'
import {
  Card,
  CardContent,
  CardAction,
  CardHeader,
  CardTitle,
  CardDescription,
} from '@/components/ui/card'
import { ArrowLeftRight } from 'lucide-react'
import { formatNum } from '@/lib/utils'
import {
  Progress,
  ProgressLabel,
  ProgressValue,
} from '@/components/ui/progress'

function useCashflowSummary(
  deposits: number | undefined,
  withdrawals: number | undefined,
) {
  return useMemo(() => {
    if (deposits == null || withdrawals == null) return null
    const inflow = deposits
    const outflow = Math.abs(withdrawals)
    const net = inflow + withdrawals
    return { inflow, outflow, net }
  }, [deposits, withdrawals])
}

export function CashflowSection() {
  const { year } = usePerformanceYear()
  const { data, error, isLoading } = useCashflow(year)
  const summary = useCashflowSummary(data?.deposits, data?.withdrawals)

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" description={error.message} />
  if (!data || !summary) return null

  const { inflow, outflow, net } = summary
  
  const items = [
    { label: 'Deposit', value: inflow },
    { label: 'Withdraw', value: outflow },
  ]

  return (
    <Card>
      <CardHeader>
        <CardDescription>Cashflow</CardDescription>
        <CardTitle className="text-xl">{formatNum(net)}</CardTitle>
        <CardAction>
          <ArrowLeftRight className="stroke-1" />
        </CardAction>
      </CardHeader>
      <CardContent className='flex flex-col gap-6'>
        {items.map(({ label, value }) => (
          <Progress
            value={(value / (inflow + outflow)) * 100}
            className="w-full"
          >
            <ProgressLabel>{label}</ProgressLabel>
            <ProgressValue />
            {`(${formatNum(value)})`}
          </Progress>
        ))}
      </CardContent>
    </Card>
  )
}
