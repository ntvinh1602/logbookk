import * as React from "react"
import { useForm } from "@tanstack/react-form"
import { toast } from "sonner"
import { NumberField } from "@/components/form/number-field"
import { TextField } from "@/components/form/text-field"
import { DateTimeField } from "@/components/form/datetime-field"
import { FieldDescription, FieldGroup } from "@/components/ui/field"
import { createClient } from "@/lib/supabase/client"
import { borrowSchema } from "./schema"
import { zodFieldValidator } from "@/components/form/zod-field-validator"

interface BorrowFormProps {
  onSuccess?: () => void
  formId: string
  onLoadingChange: (loading: boolean) => void
  resetFormRef: { current: () => void }
}

export function BorrowForm({
  onSuccess,
  formId,
  onLoadingChange,
  resetFormRef,
}: BorrowFormProps) {
  const supabase = createClient()

  const form = useForm({
    defaultValues: {
      created_at: undefined as string | undefined,
      lender: "",
      principal: "" as string,
      rate: "" as string,
    },
    onSubmit: async ({ value }) => {
      onLoadingChange(true)
      try {
        // Apply zod coercion (string inputs -> numbers)
        const values = borrowSchema.parse(value)

        const createdAt = values.created_at
          ? new Date(values.created_at).toISOString()
          : undefined

        const { error } = await supabase.rpc("add_borrow_event", {
          p_principal: values.principal,
          p_lender: values.lender,
          p_rate: values.rate,
          p_created_at: createdAt,
        })

        if (error) {
          toast.error("Transaction failed", { description: error.message })
        } else {
          toast.success("Debt added")
          form.reset()
          onSuccess?.()
        }
      } catch (err) {
        const message =
          err instanceof Error
            ? err.message
            : "An unexpected error occurred. Please try again later."
        toast.error("Unexpected error", { description: message })
      } finally {
        onLoadingChange(false)
      }
    },
  })

  // Expose form.reset() to the dialog footer via the ref
  React.useEffect(() => {
    resetFormRef.current = () => form.reset()
  }, [form, resetFormRef])

  return (
    <form
      id={formId}
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
          validators={{ onChange: zodFieldValidator(borrowSchema.shape.principal) }}
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
  )
}
