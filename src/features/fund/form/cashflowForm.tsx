import * as React from "react"
import { useSelector, useForm } from "@tanstack/react-form"
import { toast } from "sonner"
import { NumberField } from "@/components/form/number-field"
import { DateTimeField } from "@/components/form/datetime-field"
import { FieldGroup, FieldTitle } from "@/components/ui/field"
import { createClient } from "@/lib/supabase/client"
import { getCashAssets } from "@/features/fund/actions/get-cash-assets"
import type { Tables } from "@/types/database.types"
import { cashflowSchema } from "./schema"
import { ToggleGroupField } from "@/components/form/toggle-group-field"
import { SelectField } from "@/components/form/select-field"
import { txOperations } from "@/features/fund/ui/tx-filter"
import { zodFieldValidator } from "@/components/form/zod-field-validator"

const CASHFLOW_MEMO = {
  deposit: ["Cash deposit", "EPF monthly contribution", "Reconciliation"],
  withdraw: ["Reconciliation", "Cash withdrawal"],
  income: [
    "CASA balance interest",
    "EPF dividend",
    "Cash dividend from stock",
    "Other reward/income",
    "Loyalty program rewards",
  ],
  expense: ["Margin interest", "Cash advance interest", "Operational fees"],
} as const

const cashflowOps = txOperations.cashflow.map(({ key, label }) => ({
  key,
  label,
}))

interface Props {
  onSuccess?: () => void
  formId: string
  onLoadingChange: (loading: boolean) => void
  resetFormRef: { current: () => void }
}

export function CashflowForm({
  onSuccess,
  formId,
  onLoadingChange,
  resetFormRef,
}: Props) {
  const supabase = createClient()
  const [assetData, setAssetData] = React.useState<Tables<"assets">[]>([])

  React.useEffect(() => {
    getCashAssets().then(setAssetData)
  }, [])

  const form = useForm({
    defaultValues: {
      operation: "expense" as "deposit" | "withdraw" | "income" | "expense",
      created_at: undefined as string | undefined,
      asset: null as string | null,
      quantity: "" as string,
      fx_rate: undefined as string | undefined,
      memo: undefined as string | undefined,
    },
    onSubmit: async ({ value }) => {
      onLoadingChange(true)
      try {
        // Apply zod coercion (string inputs -> numbers)
        const values = cashflowSchema.parse(value)

        const createdAt = values.created_at
          ? new Date(values.created_at).toISOString()
          : undefined

        const { error } = await supabase.rpc("add_cashflow_event", {
          p_operation: values.operation,
          p_asset_id: values.asset,
          p_quantity: values.quantity,
          p_fx_rate: values.fx_rate ?? 1,
          p_memo: values.memo,
          p_created_at: createdAt,
        })

        if (error) {
          toast.error("Transaction failed", { description: error.message })
        } else {
          toast.success("Cashflow event added", { description: values.memo })
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
      .filter((a) => a.asset_class === "cash" || a.asset_class === "fund")
      .map((a) => ({
        value: a.id,
        label: a.name ? `${a.ticker} — ${a.name}` : a.ticker,
        currency: a.currency_code,
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

  const isVND = selectedAsset?.currency === "VND"

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
      <FieldGroup className="gap-6">
        <div className="flex flex-col gap-3">
          <FieldTitle>Operation</FieldTitle>
          <form.Field
            name="operation"
            validators={{ onChange: cashflowSchema.shape.operation }}
          >
            {(field) => (
              <ToggleGroupField field={field} options={cashflowOps} />
            )}
          </form.Field>
        </div>

        <div className="flex flex-col gap-3">
          <FieldTitle>Details</FieldTitle>
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
            validators={{ onChange: cashflowSchema.shape.asset }}
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
            validators={{ onChange: zodFieldValidator(cashflowSchema.shape.quantity) }}
          >
            {(field) => (
              <NumberField
                field={field}
                label="Quantity"
                placeholder="Amount in original currency"
                suffix={selectedAsset ? selectedAsset.currency : "VND"}
              />
            )}
          </form.Field>

          <form.Field
            name="fx_rate"
            validators={{ onChange: zodFieldValidator(cashflowSchema.shape.fx_rate) }}
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
  )
}
