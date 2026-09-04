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
import { ComboboxField } from '@/components/form/combobox-field'
import { DateTimeField } from '@/components/form/datetime-field'
import { Field, FieldGroup } from '@/components/ui/field'
import { stockSchema } from './schema'
import { ToggleGroupField } from '@/components/form/toggle-group-field'
import { addStockEvent } from '../api/supabase'
import { events } from '../queries/events'
import { useAddFundEvent } from '../hooks/use-add-fund-event'
import { useDebouncedValue } from '@/hooks/use-debounced-value'

const FORM_ID = 'stock-form'

export const stockOps = [
  { key: 'buy', label: 'Buy' },
  { key: 'sell', label: 'Sell' },
]

export function StockForm() {
  const [open, setOpen] = useState(false)
  const [search, setSearch] = useState('')

  // Debounce so typing doesn't fire one asset search per keystroke.
  const debouncedSearch = useDebouncedValue(search, 300)

  const assetsQuery = useQuery(events.assetSearch(debouncedSearch))

  const stockOptions = useMemo(
    () =>
      (assetsQuery.data ?? []).map((a) => ({
        value: a.id,
        label: `${a.ticker} — ${a.name}`,
      })),
    [assetsQuery.data],
  )

  const { addEvent } = useAddFundEvent({
    mutationFn: addStockEvent,
    successMessage: 'Stock transaction added',
    successDescription: (p) =>
      `${p.side.toUpperCase()} ${p.quantity} stock ID ${p.stockId} @ ${p.price}`,
  })

  const form = useForm({
    defaultValues: {
      side: 'buy',
      stock_id: 0,
      price: 0,
      quantity: 0,
      fee: 0,
      tax: 0,
      created_at: '',
    },
    validators: {
      onSubmit: stockSchema,
    },
    onSubmit: async ({ value }) => {
      try {
        await addEvent({
          side: value.side,
          stockId: value.stock_id,
          price: value.price,
          quantity: value.quantity,
          fee: value.fee,
          tax: value.tax,
          createdAt: value.created_at
            ? new Date(value.created_at).toISOString()
            : undefined,
        })
      } catch {
        // Error toast is shown by useAddFundEvent; keep the sheet open.
        return
      }

      form.reset()
      setSearch('')
      setOpen(false)
    },
  })

  const isSubmitting = useSelector(form.store, (state) => state.isSubmitting)

  const side = useSelector(form.store, (state) => state.values.side)

  const handleReset = () => {
    form.reset()
    setSearch('')
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
          <SheetTitle>Add Stock Event</SheetTitle>
          <SheetDescription>
            Record buy, sell, stock options operations
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
          <FieldGroup className="px-4">
            <form.Field name="side">
              {(field) => (
                <ToggleGroupField
                  field={field}
                  label="Operations"
                  options={stockOps}
                  onValueChange={(value) => {
                    if (value === 'buy') form.setFieldValue('tax', 0)
                  }}
                />
              )}
            </form.Field>

            <form.Field name="created_at">
              {(field) => (
                <DateTimeField field={field} label="Event Date & Time" />
              )}
            </form.Field>

            <form.Field name="stock_id">
              {(field) => (
                <ComboboxField
                  field={field}
                  label="Stock"
                  items={stockOptions}
                  onSearchChange={setSearch}
                  placeholder="Search stock by ticker"
                  emptyPlaceholder="No stock found"
                />
              )}
            </form.Field>

            <form.Field name="price">
              {(field) => (
                <NumberField field={field} label="Price" suffix="VND" />
              )}
            </form.Field>

            <form.Field name="quantity">
              {(field) => (
                <NumberField field={field} label="Quantity" suffix="Units" />
              )}
            </form.Field>

            <form.Field name="fee">
              {(field) => (
                <NumberField field={field} label="Fee" suffix="VND" />
              )}
            </form.Field>

            <form.Field name="tax">
              {(field) => (
                <NumberField
                  field={field}
                  label="Income Tax"
                  suffix="VND"
                  disabled={side === 'buy'}
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
