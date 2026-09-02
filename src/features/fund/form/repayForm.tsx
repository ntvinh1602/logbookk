import * as React from 'react'
import { useForm } from '@tanstack/react-form'
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
import { ComboboxField } from '@/components/form/combobox-field'
import { DateTimeField } from '@/components/form/datetime-field'
import { Field, FieldGroup } from '@/components/ui/field'
import { repaySchema } from './schema'
import { formatNum } from '@/lib/utils'
import { zodFieldValidator } from '@/components/form/zod-field-validator'
import { addRepayEvent, getOutstandingDebts } from '../api/supabase'
import { eventKeys } from '../queries/events'
import { dashboardKeys } from '../queries/dashboard'
import { performanceKeys } from '../queries/performance'

const FORM_ID = 'repay-form'

export function RepayForm() {
  const queryClient = useQueryClient()
  const [open, setOpen] = React.useState(false)
  const [loading, setLoading] = React.useState(false)
  const resetFormRef = React.useRef<() => void>(() => {})
  const [debtOptions, setDebtOptions] = React.useState<
    { value: string; label: string }[]
  >([])

  const form = useForm({
    defaultValues: {
      created_at: undefined as string | undefined,
      repay_tx: null as string | null,
      interest: '',
    },
    onSubmit: async ({ value }) => {
      setLoading(true)
      try {
        const values = repaySchema.parse(value)

        const createdAt = values.created_at
          ? new Date(values.created_at).toISOString()
          : undefined

        await addRepayEvent({
          repayTx: values.repay_tx,
          interest: values.interest,
          createdAt,
        })

        toast.success('Repay event added')
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

  React.useEffect(() => {
    getOutstandingDebts()
      .then((data) =>
        setDebtOptions(
          data.map((d) => ({
            value: d.tx_id,
            label: `${d.lender} — ${formatNum(d.principal)} at ${d.rate}%`,
          })),
        ),
      )
      .catch((err) =>
        toast.error('Failed to load debts', { description: err.message }),
      )
  }, [])

  React.useEffect(() => {
    resetFormRef.current = () => form.reset()
  }, [form])

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger render={<Button><PlusIcon /> Add Event</Button>} />
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
          <FieldGroup className="gap-3">
            <form.Field
              name="created_at"
              validators={{ onChange: repaySchema.shape.created_at }}
            >
              {(field) => <DateTimeField field={field} label="Date & Time" />}
            </form.Field>

            <form.Field
              name="repay_tx"
              validators={{
                onChange: zodFieldValidator(repaySchema.shape.repay_tx),
              }}
            >
              {(field) => (
                <ComboboxField
                  field={field}
                  label="Deal"
                  items={debtOptions}
                  placeholder="Select debt"
                />
              )}
            </form.Field>

            <form.Field
              name="interest"
              validators={{
                onChange: zodFieldValidator(repaySchema.shape.interest),
              }}
            >
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
