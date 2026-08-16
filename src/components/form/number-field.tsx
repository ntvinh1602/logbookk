import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
  InputGroupText,
} from "@/components/ui/input-group"
import type { AnyFieldApi } from "@tanstack/react-form"
import { Field, FieldLabel, FieldError } from "@/components/ui/field"
import { toFieldErrorMessages } from "./field-errors"

interface NumberFieldProps {
  field: AnyFieldApi
  label: string
  placeholder?: string
  suffix?: string
  disabled?: boolean
}

export function NumberField({
  field,
  label,
  placeholder,
  suffix,
  disabled,
}: NumberFieldProps) {
  const errors = toFieldErrorMessages(field.state.meta.errors)

  return (
    <Field data-invalid={errors.length > 0} data-disabled={disabled}>
      <FieldLabel className="sr-only">{label}</FieldLabel>
      <InputGroup>
        <InputGroupInput
          type="number"
          value={field.state.value ?? ""}
          onChange={(e) => field.handleChange(e.target.value)}
          inputMode="decimal"
          placeholder={placeholder}
          disabled={disabled}
        />
        {suffix && (
          <InputGroupAddon align="inline-end">
            <InputGroupText className="text-nowrap">
              {suffix}
            </InputGroupText>
          </InputGroupAddon>
        )}
      </InputGroup>
      {errors.length > 0 && <FieldError errors={errors} />}
    </Field>
  )
}
