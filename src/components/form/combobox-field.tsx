import type { AnyFieldApi } from "@tanstack/react-form"
import { Field, FieldLabel, FieldError } from "@/components/ui/field"
import {
  Combobox,
  ComboboxContent,
  ComboboxEmpty,
  ComboboxInput,
  ComboboxItem,
  ComboboxList,
} from "@/components/ui/combobox"
import { toFieldErrorMessages } from "./field-errors"

type ComboboxOption = {
  value: string
  label: string
}

interface ComboboxFieldProps {
  field: AnyFieldApi
  label: string
  items: ComboboxOption[]
  placeholder?: string
  emptyPlaceholder?: string
  onSearchChange?: (value: string) => void
}

export function ComboboxField({
  field,
  label,
  items,
  placeholder,
  emptyPlaceholder,
  onSearchChange,
}: ComboboxFieldProps) {
  const errors = toFieldErrorMessages(field.state.meta.errors)

  return (
    <Field data-invalid={errors.length > 0}>
      <FieldLabel>{label}</FieldLabel>
      <Combobox
        items={items}
        value={
          field.state.value
            ? (items.find((item) => item.value === field.state.value) ?? null)
            : null
        }
        onValueChange={(item) => field.handleChange(item ? item.value : null)}
        itemToStringLabel={(item: ComboboxOption) => item.label}
        isItemEqualToValue={(a, b) => a.value === b.value}
      >
        <ComboboxInput
          placeholder={placeholder}
          onChange={(e) => onSearchChange?.(e.target.value)}
          showClear
        />
        <ComboboxContent>
          <ComboboxEmpty>{emptyPlaceholder}</ComboboxEmpty>
          <ComboboxList>
            {(item) => (
              <ComboboxItem key={item.value} value={item}>
                {item.label}
              </ComboboxItem>
            )}
          </ComboboxList>
        </ComboboxContent>
      </Combobox>
      {errors.length > 0 && <FieldError errors={errors} />}
    </Field>
  )
}
