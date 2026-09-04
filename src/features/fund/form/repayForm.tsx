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
import { repaySchema } from './schema'
import { formatNum } from '@/lib/utils'
import { addRepayEvent } from '../api/supabase'
import { events } from '../queries/events'
import { useAddFundEvent } from '../hooks/use-add-fund-event'

const FORM_ID = 'repay-form'

export function RepayForm() {
  const [open, setOpen] = useState(false)

  const debtsQuery = useQuery(events.outstandingDebts())

  const debtOptions = useMemo(
    () =>
      (debtsQuery.data ?? []).map((d) => ({
        value: d.tx_id,
        label: `${d.lender} — ${formatNum(d.principal)} at ${d.rate}%`,
      })),
    [debtsQuery.data],
  )

  const { addEvent } = useAddFundEvent({
    mutationFn: addRepayEvent,
    successMessage: 'Repay event added',
  })

  const form = useForm({
    defaultValues: {
      created_at: '',
      repay_tx: 0,
      interest: 0,
    },
    validators: {
      onSubmit: repaySchema,
    },
    onSubmit: async ({ value }) => {
      try {
        await addEvent({
          repayTx: value.repay_tx,
          interest: value.interest,
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
          <SheetTitle>Add Repay Event</SheetTitle>
          <SheetDescription>Record a debt settlement</SheetDescription>
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
            <form.Field name="created_at">
              {(field) => <DateTimeField field={field} label="Date & Time" />}
            </form.Field>

            <form.Field name="repay_tx">
              {(field) => (
                <ComboboxField
                  field={field}
                  label="Deal"
                  items={debtOptions}
                  placeholder="Select debt"
                />
              )}
            </form.Field>

            <form.Field name="interest">
              {(field) => (
                <NumberField
                  field={field}
                  label="Paid Interest"
                  placeholder="Interest paid"
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
