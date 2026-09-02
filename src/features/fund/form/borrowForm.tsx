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
import { TextField } from '@/components/form/text-field'
import { DateTimeField } from '@/components/form/datetime-field'
import { Field, FieldDescription, FieldGroup } from '@/components/ui/field'
import { borrowSchema } from './schema'
import { zodFieldValidator } from '@/components/form/zod-field-validator'
import { addBorrowEvent } from '../api/supabase'
import { eventKeys } from '../queries/events'
import { dashboardKeys } from '../queries/dashboard'
import { performanceKeys } from '../queries/performance'

const FORM_ID = 'borrow-form'

export function BorrowForm() {
  const queryClient = useQueryClient()
  const [open, setOpen] = React.useState(false)
  const [loading, setLoading] = React.useState(false)
  const resetFormRef = React.useRef<() => void>(() => {})

  const form = useForm({
    defaultValues: {
      created_at: undefined as string | undefined,
      lender: '',
      principal: '',
      rate: '',
    },
    onSubmit: async ({ value }) => {
      setLoading(true)
      try {
        const values = borrowSchema.parse(value)

        const createdAt = values.created_at
          ? new Date(values.created_at).toISOString()
          : undefined

        await addBorrowEvent({
          principal: values.principal,
          lender: values.lender,
          rate: values.rate,
          createdAt,
        })

        toast.success('Debt added')
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
    resetFormRef.current = () => form.reset()
  }, [form])

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger render={<Button><PlusIcon /> Add Event</Button>} />
      <SheetContent>
        <SheetHeader>
          <SheetTitle>Add Borrow Event</SheetTitle>
          <SheetDescription>Record a new debt</SheetDescription>
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
              validators={{ onChange: borrowSchema.shape.created_at }}
            >
              {(field) => <DateTimeField field={field} label="Date & Time" />}
            </form.Field>

            <form.Field
              name="lender"
              validators={{ onChange: borrowSchema.shape.lender }}
            >
              {(field) => (
                <TextField field={field} label="Lender" placeholder="Lender name" />
              )}
            </form.Field>
            <FieldDescription className="text-right">
              Note: Add unique identifier for repeated lenders
            </FieldDescription>
            <form.Field
              name="principal"
              validators={{
                onChange: zodFieldValidator(borrowSchema.shape.principal),
              }}
            >
              {(field) => (
                <NumberField
                  field={field}
                  label="Debt Principal"
                  placeholder="Debt principal in whole number"
                  suffix="VND"
                />
              )}
            </form.Field>

            <form.Field
              name="rate"
              validators={{ onChange: zodFieldValidator(borrowSchema.shape.rate) }}
            >
              {(field) => (
                <NumberField
                  field={field}
                  label="Interest rate"
                  placeholder="Interest rate"
                  suffix="% p.a"
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
