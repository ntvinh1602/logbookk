import { Input } from "@/components/ui/input"
import type { AnyFieldApi } from "@tanstack/react-form"
import { Field, FieldLabel, FieldError } from "@/components/ui/field"
import { toFieldErrorMessages } from "./field-errors"

interface TextFieldProps {
  field: AnyFieldApi
  label: string
  placeholder?: string
  disabled?: boolean
}

export function TextField({
  field,
  label,
  placeholder,
  disabled,
}: TextFieldProps) {
  const errors = toFieldErrorMessages(field.state.meta.errors)

  return (
    <Field data-invalid={errors.length > 0} data-disabled={disabled}>
      <FieldLabel className="sr-only">{label}</FieldLabel>
      <Input
        type="text"
        value={field.state.value ?? ""}
        onChange={(e) => field.handleChange(e.target.value)}
        inputMode="text"
        placeholder={placeholder}
        disabled={disabled}
      />
      {errors.length > 0 && <FieldError errors={errors} />}
    </Field>
  )
}
