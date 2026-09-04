import { useState, useMemo } from 'react'
import { useSelector, useForm } from '@tanstack/react-form'
import { useQuery } from '@tanstack/react-query'
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
import { addCashflowEvent } from '../api/supabase'
import { events } from '../queries/events'
import { useAddFundEvent } from '../hooks/use-add-fund-event'

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
  { key: 'deposit', label: 'Deposit' },
  { key: 'withdraw', label: 'Withdraw' },
  { key: 'income', label: 'Income' },
  { key: 'expense', label: 'Expense' },
]

export function CashflowForm() {
  const [open, setOpen] = useState(false)

  const assetsQuery = useQuery(events.cashAssets())

  const assetOptions = useMemo(() => {
    const seen = new Set<number>()
    return (assetsQuery.data ?? [])
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
  }, [assetsQuery.data])

  const { addEvent } = useAddFundEvent({
    mutationFn: addCashflowEvent,
    successMessage: 'Cashflow event added',
    successDescription: (p) => p.memo,
  })

  const form = useForm({
    defaultValues: {
      operation: 'expense' as 'deposit' | 'withdraw' | 'income' | 'expense',
      created_at: '',
      asset: 0,
      quantity: 0,
      fx_rate: 1,
      memo: '',
    },
    validators: {
      onSubmit: cashflowSchema,
    },
    onSubmit: async ({ value }) => {
      try {
        await addEvent({
          operation: value.operation,
          assetId: value.asset,
          quantity: value.quantity,
          fxRate: value.fx_rate,
          memo: value.memo,
          createdAt: value.created_at
            ? new Date(value.created_at).toISOString()
            : undefined,
        })
      } catch {
        // Error toast is shown by useAddFundEvent; keep the sheet open.
        return
      }

      form.reset()
      setOpen(false)
    },
  })

  const isSubmitting = useSelector(form.store, (state) => state.isSubmitting)
  const operation = useSelector(form.store, (state) => state.values.operation)
  const selectedAssetId = useSelector(form.store, (state) => state.values.asset)

  const filteredMemos = useMemo(() => {
    return CASHFLOW_MEMO[operation].map((memo) => ({
      value: memo,
      label: memo,
    }))
  }, [operation])

  const selectedAsset = useMemo(() => {
    return assetOptions.find((a) => a.value === selectedAssetId)
  }, [assetOptions, selectedAssetId])

  const isVND = selectedAsset?.currency === 'VND'

  const handleReset = () => {
    form.reset()
  }

  const handleOpenChange = (open: boolean) => {
    setOpen(open)
    if (!open) handleReset()
  }

  return (
    <Sheet open={open} onOpenChange={handleOpenChange}>
      <SheetTrigger
        render={
          <Button>
            <PlusIcon /> Add Event
          </Button>
        }
      />
      <SheetContent>
        <SheetHeader>
          <SheetTitle>Add Cashflow Event</SheetTitle>
          <SheetDescription>Record cash assets transactions</SheetDescription>
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
          <FieldGroup className="px-4">
            <form.Field name="operation">
              {(field) => (
                <ToggleGroupField
                  field={field}
                  label="Operation"
                  options={cashflowOps}
                />
              )}
            </form.Field>

            <form.Field name="created_at">
              {(field) => <DateTimeField field={field} label="Date & Time" />}
            </form.Field>

            <form.Field name="memo">
              {(field) => (
                <SelectField
                  field={field}
                  label="Description"
                  placeholder="Event description"
                  options={filteredMemos}
                />
              )}
            </form.Field>

            <form.Field name="asset">
              {(field) => (
                <SelectField
                  field={field}
                  label="Asset"
                  placeholder="Cash / fund asset"
                  options={assetOptions}
                  onValueChange={(assetId) => {
                    const currency = assetOptions.find(
                      (a) => a.value === assetId,
                    )?.currency
                    if (currency === 'VND') form.setFieldValue('fx_rate', 1)
                  }}
                />
              )}
            </form.Field>

            <form.Field name="quantity">
              {(field) => (
                <NumberField
                  field={field}
                  label="Quantity"
                  placeholder="Amount in original currency"
                  suffix={selectedAsset ? selectedAsset.currency : 'VND'}
                />
              )}
            </form.Field>

            <form.Field name="fx_rate">
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
          </FieldGroup>
        </form>
        <SheetFooter>
          <Field>
            <Button type="button" variant="outline" onClick={handleReset}>
              Reset
            </Button>
            <Button type="submit" form={FORM_ID} disabled={isSubmitting}>
              {isSubmitting ? 'Submitting...' : 'Submit'}
            </Button>
          </Field>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  )
}
