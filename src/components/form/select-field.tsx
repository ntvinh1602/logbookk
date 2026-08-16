import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select"
import type { AnyFieldApi } from "@tanstack/react-form"
import { Field, FieldLabel, FieldError } from "@/components/ui/field"
import { toFieldErrorMessages } from "./field-errors"

interface SelectOption {
  label: string
  value: string
}

interface SelectFieldProps {
  field: AnyFieldApi
  label: string
  placeholder?: string
  options: SelectOption[]
  disabled?: boolean
}

export function SelectField({
  field,
  label,
  placeholder,
  options,
  disabled,
}: SelectFieldProps) {
  const errors = toFieldErrorMessages(field.state.meta.errors)

  return (
    <Field data-invalid={errors.length > 0} data-disabled={disabled}>
      <FieldLabel className="sr-only">{label}</FieldLabel>

      <Select
        onValueChange={(value) => field.handleChange(value ?? null)}
        value={field.state.value ?? undefined}
        items={options}
        disabled={disabled}
      >
        <SelectTrigger>
          <SelectValue placeholder={placeholder} />
        </SelectTrigger>
        <SelectContent alignItemWithTrigger={false}>
          {options.map((option) => (
            <SelectItem key={option.value} value={option.value}>
              {option.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>

      {errors.length > 0 && <FieldError errors={errors} />}
    </Field>
  )
}
