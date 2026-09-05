import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import type { AnyFieldApi } from '@tanstack/react-form'
import { Field, FieldError, FieldLabel } from '@/components/ui/field'
import { toFieldErrorMessages } from './field-errors'

interface SelectOption {
  label: string
  value: string | number
}

interface SelectFieldProps {
  field: AnyFieldApi
  label: string
  placeholder?: string
  options: SelectOption[]
  disabled?: boolean
  /** Called with the newly selected value after the field value is updated. */
  onValueChange?: (value: string | number) => void
}

export function SelectField({
  field,
  label,
  placeholder,
  options,
  disabled,
  onValueChange,
}: SelectFieldProps) {
  const errors = toFieldErrorMessages(field.state.meta.errors)

  return (
    <Field data-invalid={errors.length > 0} data-disabled={disabled}>
      <FieldLabel>{label}</FieldLabel>

      <Select
        onValueChange={(value) => {
          field.handleChange(value ?? null)
          if (value != null) onValueChange?.(value)
        }}
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
