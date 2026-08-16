import * as React from "react"
import { useSelector, useForm } from "@tanstack/react-form"
import { toast } from "sonner"
import { NumberField } from "@/components/form/number-field"
import { ComboboxField } from "@/components/form/combobox-field"
import { DateTimeField } from "@/components/form/datetime-field"
import { FieldGroup, FieldTitle } from "@/components/ui/field"
import { createClient } from "@/lib/supabase/client"
import { stockSchema } from "./schema"
import {
  searchAssets,
  type AssetSearchResult,
} from "@/features/fund/actions/search-assets"
import { ToggleGroupField } from "@/components/form/toggle-group-field"
import { txOperations } from "@/features/fund/ui/tx-filter"
import { zodFieldValidator } from "@/components/form/zod-field-validator"

export const stockOps = txOperations.stock.map(({ key, label }) => ({
  key,
  label,
}))

interface StockFormProps {
  onSuccess?: () => void
  formId: string
  onLoadingChange: (loading: boolean) => void
  resetFormRef: { current: () => void }
}

export function StockForm({
  onSuccess,
  formId,
  onLoadingChange,
  resetFormRef,
}: StockFormProps) {
  const supabase = createClient()
  const [search, setSearch] = React.useState("")
  const [assets, setAssets] = React.useState<AssetSearchResult[]>([])

  React.useEffect(() => {
    if (search.length < 2) return
    const timer = setTimeout(() => {
      searchAssets(search, "stock").then(setAssets)
    }, 300)
    return () => clearTimeout(timer)
  }, [search])

  const stockOptions = React.useMemo(
    () =>
      search.length < 2
        ? []
        : assets.map((a) => ({
            value: a.ticker,
            label: `${a.ticker} — ${a.name}`,
          })),
    [assets, search.length],
  )

  const form = useForm({
    defaultValues: {
      side: "buy" as "buy" | "sell",
      created_at: undefined as string | undefined,
      ticker: undefined as string | undefined,
      price: "" as string,
      quantity: "" as string,
      fee: "" as string,
      tax: undefined as string | undefined,
    },
    onSubmit: async ({ value }) => {
      onLoadingChange(true)
      try {
        // Apply zod coercion (string inputs -> numbers)
        const values = stockSchema.parse(value)

        // new Date() interprets naive string in the browser's local timezone
        const createdAt = values.created_at
          ? new Date(values.created_at).toISOString()
          : undefined

        const { error } = await supabase.rpc("add_stock_event", {
          p_side: values.side,
          p_ticker: values.ticker,
          p_price: values.price,
          p_quantity: values.quantity,
          p_fee: values.fee,
          p_tax: values.tax ?? 0,
          p_created_at: createdAt,
        })

        if (error) {
          toast.error("Transaction failed", {
            description: error.message,
          })
        } else {
          toast.success("Stock transaction added", {
            description: `${values.side.toUpperCase()} ${values.quantity} ${values.ticker} @ ${values.price}`,
          })
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

  const side = useSelector(form.store, (state) => state.values.side)

  // Expose form.reset() to the dialog footer via the ref
  React.useEffect(() => {
    resetFormRef.current = () => form.reset()
  }, [form, resetFormRef])

  // Reset tax when switching to "buy" — tax only applies to sells.
  // Without this, a value entered during "sell" persists in form state
  // and is submitted via p_tax: values.tax ?? 0.
  React.useEffect(() => {
    if (side === "buy") form.setFieldValue("tax", undefined)
  }, [side, form])

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
            name="side"
            validators={{ onChange: stockSchema.shape.side }}
          >
            {(field) => <ToggleGroupField field={field} options={stockOps} />}
          </form.Field>
        </div>

        <div className="flex flex-col gap-3">
          <FieldTitle>Details</FieldTitle>
          <form.Field
            name="created_at"
            validators={{ onChange: stockSchema.shape.created_at }}
          >
            {(field) => <DateTimeField field={field} label="Date Time" />}
          </form.Field>

          <form.Field
            name="ticker"
            validators={{ onChange: stockSchema.shape.ticker }}
          >
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

          <form.Field
            name="price"
            validators={{ onChange: zodFieldValidator(stockSchema.shape.price) }}
          >
            {(field) => (
              <NumberField
                field={field}
                label="Price"
                placeholder="Matched price in whole number"
                suffix="VND"
              />
            )}
          </form.Field>

          <form.Field
            name="quantity"
            validators={{ onChange: zodFieldValidator(stockSchema.shape.quantity) }}
          >
            {(field) => (
              <NumberField
                field={field}
                label="Quantity"
                placeholder="Number of shares"
                suffix="Units"
              />
            )}
          </form.Field>

          <form.Field
            name="fee"
            validators={{ onChange: zodFieldValidator(stockSchema.shape.fee) }}
          >
            {(field) => (
              <NumberField
                field={field}
                label="Fee"
                placeholder="Transaction fees"
                suffix="VND"
              />
            )}
          </form.Field>

          <form.Field
            name="tax"
            validators={{ onChange: zodFieldValidator(stockSchema.shape.tax) }}
          >
            {(field) => (
              <NumberField
                field={field}
                label="Tax"
                placeholder="Income tax"
                suffix="VND"
                disabled={side === "buy"}
              />
            )}
          </form.Field>
        </div>
      </FieldGroup>
    </form>
  )
}
