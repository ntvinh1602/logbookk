import type { CashflowSummary } from '@/features/fund/types'
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

interface CashflowSectionProps {
  data: CashflowSummary | undefined
  isLoading: boolean
}

export function CashflowSection({ data, isLoading }: CashflowSectionProps) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!data) return null

  const netflow = data.deposits + data.withdrawals
  const totalflow = data.deposits + Math.abs(data.withdrawals)

  const items = [
    { label: 'Deposit', value: data.deposits },
    { label: 'Withdraw', value: Math.abs(data.withdrawals) },
  ]

  return (
    <Card>
      <CardHeader>
        <CardDescription>Cashflow</CardDescription>
        <CardTitle className="text-xl">{formatNum(netflow)}</CardTitle>
        <CardAction>
          <ArrowLeftRight className="stroke-1" />
        </CardAction>
      </CardHeader>
      <CardContent className="flex flex-col gap-6">
        {items.map(({ label, value }) => (
          <Progress value={(value / totalflow) * 100} className="w-full">
            <ProgressLabel>{label}</ProgressLabel>
            <ProgressValue />
            {`(${formatNum(value)})`}
          </Progress>
        ))}
      </CardContent>
    </Card>
  )
}
