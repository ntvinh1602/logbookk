import type { ProfitChartCols } from '@/lib/supabase/api/types'
import StatusLabel from '@/components/status-label'
import {
  Card,
  CardContent,
  CardAction,
  CardHeader,
  CardTitle,
  CardDescription,
} from '@/components/ui/card'
import { Receipt } from 'lucide-react'
import { formatNum } from '@/lib/utils'
import {
  Progress,
  ProgressLabel,
  ProgressValue,
} from '@/components/ui/progress'

const sum = (xs: number[] | null) =>
  (xs ?? []).reduce((acc, n) => acc + (n || 0), 0)

interface ExpenseChartSectionProps {
  monthlyPnlChart: ProfitChartCols | undefined
  isLoading: boolean
}

export function ExpenseChartSection({
  monthlyPnlChart,
  isLoading,
}: ExpenseChartSectionProps) {
  if (isLoading) return <StatusLabel type="loading" />
  if (!monthlyPnlChart) return null

  const tax = -sum(monthlyPnlChart.tax)
  const fee = -sum(monthlyPnlChart.fee)
  const interest = -sum(monthlyPnlChart.interest)
  const totalExpenses = tax + fee + interest

  const expenses = [
    { label: 'Tax', value: tax },
    { label: 'Fee', value: fee },
    { label: 'Interest', value: interest },
  ]

  return (
    <Card>
      <CardHeader>
        <CardDescription>Total Expenses</CardDescription>
        <CardTitle className="text-xl">{formatNum(totalExpenses)}</CardTitle>
        <CardAction>
          <Receipt className="stroke-1" />
        </CardAction>
      </CardHeader>
      <CardContent className="flex flex-col gap-6">
        {expenses.map(({ label, value }) => (
          <Progress
            key={label}
            value={(value / totalExpenses) * 100}
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
