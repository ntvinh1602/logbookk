import * as React from 'react'
import { useSelector, useForm } from '@tanstack/react-form'
import { useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { PlusIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'

import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from '@/components/ui/sheet'
import { NumberField } from '@/components/form/number-field'
import { DateTimeField } from '@/components/form/datetime-field'
import { Field, FieldGroup } from '@/components/ui/field'
import { cashflowSchema } from './schema'
import { ToggleGroupField } from '@/components/form/toggle-group-field'
import { SelectField } from '@/components/form/select-field'
import { zodFieldValidator } from '@/components/form/zod-field-validator'
import { addCashflowEvent, getCashAssets } from '../api/supabase'
import { eventKeys } from '../queries/events'
import { dashboardKeys } from '../queries/dashboard'
import { performanceKeys } from '../queries/performance'
import type { AssetSearchResult } from '../fund.types'

const FORM_ID = 'cashflow-form'

const CASHFLOW_MEMO = {
  deposit: ['Cash deposit', 'EPF monthly contribution', 'Reconciliation'],
  withdraw: ['Reconciliation', 'Cash withdrawal'],
  income: [
    'CASA balance interest',
    'EPF dividend',
    'Cash dividend from stock',
    'Other reward/income',
    'Loyalty program rewards',
  ],
  expense: ['Margin interest', 'Cash advance interest', 'Operational fees'],
} as const

const cashflowOps = [
  { key: 'deposit', label: 'Buy' },
  { key: 'withdraw', label: 'Withdraw' },
  { key: 'income', label: 'Income' },
  { key: 'expense', label: 'Expense' },
]

export function CashflowForm() {
  const queryClient = useQueryClient()
  const [open, setOpen] = React.useState(false)
  const [loading, setLoading] = React.useState(false)
  const resetFormRef = React.useRef<() => void>(() => {})
  const [assetData, setAssetData] = React.useState<AssetSearchResult[]>([])

  React.useEffect(() => {
    getCashAssets().then(setAssetData)
  }, [])

  const form = useForm({
    defaultValues: {
      operation: 'expense' as 'deposit' | 'withdraw' | 'income' | 'expense',
      created_at: undefined as string | undefined,
      asset: null as string | null,
      quantity: '',
      fx_rate: undefined as string | undefined,
      memo: undefined as string | undefined,
    },
    onSubmit: async ({ value }) => {
      setLoading(true)
      try {
        const values = cashflowSchema.parse(value)

        const createdAt = values.created_at
          ? new Date(values.created_at).toISOString()
          : undefined

        await addCashflowEvent({
          operation: values.operation,
          assetId: values.asset,
          quantity: values.quantity,
          fxRate: values.fx_rate ?? 1,
          memo: values.memo,
          createdAt,
        })

        toast.success('Cashflow event added', { description: values.memo })
        form.reset()
        queryClient.invalidateQueries({ queryKey: eventKeys.all })
        queryClient.invalidateQueries({ queryKey: dashboardKeys.all })
        queryClient.invalidateQueries({ queryKey: performanceKeys.all })
        setOpen(false)
      } catch (err) {
        const message =
          err instanceof Error
            ? err.message
            : 'An unexpected error occurred. Please try again later.'
        toast.error('Unexpected error', { description: message })
      } finally {
        setLoading(false)
      }
    },
  })

  const operation = useSelector(form.store, (state) => state.values.operation)
  const selectedAssetId = useSelector(form.store, (state) => state.values.asset)

  const filteredMemos = React.useMemo(() => {
    if (!operation) return []

    return (
      CASHFLOW_MEMO[operation]?.map((memo) => ({
        value: memo,
        label: memo,
      })) ?? []
    )
  }, [operation])

  const assetIDs = React.useMemo(() => {
    const seen = new Set<string>()
    return assetData
      .map((a) => ({
        value: a.id,
        label: a.name ? `${a.ticker} — ${a.name}` : a.ticker,
        currency: a.currency,
      }))
      .filter((item) => {
        if (seen.has(item.value)) return false
        seen.add(item.value)
        return true
      })
  }, [assetData])

  const selectedAsset = React.useMemo(() => {
    return assetIDs.find((a) => a.value === selectedAssetId)
  }, [assetIDs, selectedAssetId])

  const isVND = selectedAsset?.currency === 'VND'

  React.useEffect(() => {
    resetFormRef.current = () => form.reset()
  }, [form])

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger render={<Button><PlusIcon /> Add Event</Button>} />
      <SheetContent>
        <SheetHeader>
          <SheetTitle>Add Cashflow Event</SheetTitle>
          <SheetDescription>
            Record cash assets transactions
          </SheetDescription>
        </SheetHeader>
        <form
          id={FORM_ID}
          noValidate
          onSubmit={(e) => {
            e.preventDefault()
            e.stopPropagation()
            void form.handleSubmit()
          }}
        >
          <FieldGroup className="gap-6">
            <form.Field
              name="operation"
              validators={{ onChange: cashflowSchema.shape.operation }}
            >
              {(field) => (
                <ToggleGroupField field={field} label="Operation" options={cashflowOps} />
              )}
            </form.Field>

            <div className="flex flex-col gap-3">
              <form.Field
                name="created_at"
                validators={{ onChange: cashflowSchema.shape.created_at }}
              >
                {(field) => <DateTimeField field={field} label="Date time" />}
              </form.Field>

              <form.Field
                name="memo"
                validators={{ onChange: cashflowSchema.shape.memo }}
              >
                {(field) => (
                  <SelectField
                    field={field}
                    label="Description"
                    placeholder="Event description"
                    options={filteredMemos}
                  />
                )}
              </form.Field>

              <form.Field
                name="asset"
                validators={{
                  onChange: zodFieldValidator(cashflowSchema.shape.asset),
                }}
              >
                {(field) => (
                  <SelectField
                    field={field}
                    label="Asset"
                    placeholder="Cash / fund asset"
                    options={assetIDs}
                  />
                )}
              </form.Field>

              <form.Field
                name="quantity"
                validators={{
                  onChange: zodFieldValidator(cashflowSchema.shape.quantity),
                }}
              >
                {(field) => (
                  <NumberField
                    field={field}
                    label="Quantity"
                    placeholder="Amount in original currency"
                    suffix={selectedAsset ? selectedAsset.currency : 'VND'}
                  />
                )}
              </form.Field>

              <form.Field
                name="fx_rate"
                validators={{
                  onChange: zodFieldValidator(cashflowSchema.shape.fx_rate),
                }}
              >
                {(field) => (
                  <NumberField
                    field={field}
                    label="FX Rate"
                    placeholder="Exchange rate to VND"
                    disabled={isVND}
                    suffix="VND"
                  />
                )}
              </form.Field>
            </div>
          </FieldGroup>
        </form>
        <SheetFooter>
          <Field>
            <Button
              type="button"
              variant="outline"
              onClick={() => resetFormRef.current()}
            >
              Reset
            </Button>
            <Button type="submit" form={FORM_ID} disabled={loading}>
              {loading ? 'Submitting...' : 'Submit'}
            </Button>
          </Field>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  )
}
