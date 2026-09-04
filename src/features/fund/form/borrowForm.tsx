import { useState } from 'react'
import { useSelector, useForm } from '@tanstack/react-form'
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
import { addBorrowEvent } from '../api/supabase'
import { useAddFundEvent } from '../hooks/use-add-fund-event'

const FORM_ID = 'borrow-form'

export function BorrowForm() {
  const [open, setOpen] = useState(false)

  const { addEvent } = useAddFundEvent({
    mutationFn: addBorrowEvent,
    successMessage: 'Debt added',
  })

  const form = useForm({
    defaultValues: {
      created_at: '',
      lender: '',
      principal: 0,
      rate: 0,
    },
    validators: {
      onSubmit: borrowSchema,
    },
    onSubmit: async ({ value }) => {
      try {
        await addEvent({
          principal: value.principal,
          lender: value.lender,
          rate: value.rate,
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
          <FieldGroup className="px-4">
            <form.Field name="created_at">
              {(field) => <DateTimeField field={field} label="Date & Time" />}
            </form.Field>

            <form.Field name="lender">
              {(field) => (
                <TextField
                  field={field}
                  label="Lender"
                  placeholder="Lender name"
                />
              )}
            </form.Field>
            <FieldDescription className="text-right">
              Note: Add unique identifier for repeated lenders
            </FieldDescription>

            <form.Field name="principal">
              {(field) => (
                <NumberField
                  field={field}
                  label="Debt Principal"
                  placeholder="Debt principal in whole number"
                  suffix="VND"
                />
              )}
            </form.Field>

            <form.Field name="rate">
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
