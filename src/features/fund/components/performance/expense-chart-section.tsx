import { useMemo } from 'react'
import { usePerformanceYear } from './year-context'
import { useProfit } from '@/features/fund/hooks/use-performance-data'
import type { ProfitChartCols } from '@/features/fund/fund.types'
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

function useExpenseChartData(profitChart: ProfitChartCols | undefined): {
  totalExpenses: number
  tax: number
  fee: number
  interest: number
} | null {
  return useMemo(() => {
    if (!profitChart) return null
    const tax = -sum(profitChart.tax)
    const fee = -sum(profitChart.fee)
    const interest = -sum(profitChart.interest)
    const totalExpenses = tax + fee + interest
    return { totalExpenses, tax, fee, interest }
  }, [profitChart])
}

export function ExpenseChartSection() {
  const { year } = usePerformanceYear()
  const { data, error, isLoading } = useProfit(year)
  const expenseData = useExpenseChartData(
    data?.profit_chart as ProfitChartCols | undefined,
  )

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" description={error.message} />
  if (!data || !expenseData) return null

  const { totalExpenses, tax, fee, interest } = expenseData

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
      <CardContent className='flex flex-col gap-6'>
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
