import * as React from "react"
import { useForm } from "@tanstack/react-form"
import { toast } from "sonner"
import { NumberField } from "@/components/form/number-field"
import { ComboboxField } from "@/components/form/combobox-field"
import { DateTimeField } from "@/components/form/datetime-field"
import { FieldGroup } from "@/components/ui/field"
import { createClient } from "@/lib/supabase/client"
import { repaySchema } from "./schema"
import { formatNum } from "@/lib/utils"
import { zodFieldValidator } from "@/components/form/zod-field-validator"

interface RepayFormProps {
  onSuccess?: () => void
  formId: string
  onLoadingChange: (loading: boolean) => void
  resetFormRef: { current: () => void }
}

export function RepayForm({
  onSuccess,
  formId,
  onLoadingChange,
  resetFormRef,
}: RepayFormProps) {
  const supabase = createClient()
  const [debtOptions, setDebtOptions] = React.useState<
    { value: string; label: string }[]
  >([])

  const form = useForm({
    defaultValues: {
      created_at: undefined as string | undefined,
      repay_tx: null as string | null,
      interest: "" as string,
    },
    onSubmit: async ({ value }) => {
      onLoadingChange(true)
      try {
        // Apply zod coercion (string input -> number)
        const values = repaySchema.parse(value)

        const createdAt = values.created_at
          ? new Date(values.created_at).toISOString()
          : undefined

        const { error } = await supabase.rpc("add_repay_event", {
          p_repay_tx: values.repay_tx,
          p_interest: values.interest,
          p_created_at: createdAt,
        })

        if (error) {
          toast.error("Transaction failed", { description: error.message })
        } else {
          toast.success("Repay event added")
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

  React.useEffect(() => {
    async function loadDebts() {
      const { data, error } = await supabase
        .from("outstanding_debts")
        .select("tx_id,lender,principal,rate")

      if (error) {
        toast.error("Failed to load debts", { description: error.message })
        return
      }

      setDebtOptions(
        data.map((d) => ({
          value: d.tx_id,
          label: `${d.lender} — ${formatNum(d.principal)} at ${d.rate}%`,
        })),
      )
    }

    loadDebts()
  }, [supabase])

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
          validators={{ onChange: repaySchema.shape.created_at }}
        >
          {(field) => <DateTimeField field={field} label="Date & Time" />}
        </form.Field>

        <form.Field
          name="repay_tx"
          validators={{ onChange: repaySchema.shape.repay_tx }}
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
          validators={{ onChange: zodFieldValidator(repaySchema.shape.interest) }}
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
  )
}
