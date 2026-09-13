import { Input } from '@/components/ui/input'
import type { AnyFieldApi } from '@tanstack/react-form'
import {
  Field,
  FieldLabel,
  FieldError,
  FieldDescription,
} from '@/components/ui/field'
import { toFieldErrorMessages } from '@/components/form/field-errors'

interface TextFieldProps {
  field: AnyFieldApi
  label: string
  placeholder?: string
  description?: string
  disabled?: boolean
}

export function TextField({
  field,
  label,
  placeholder,
  description,
  disabled,
}: TextFieldProps) {
  const errors = toFieldErrorMessages(field.state.meta.errors)

  return (
    <Field data-invalid={errors.length > 0} data-disabled={disabled}>
      <FieldLabel>{label}</FieldLabel>
      <Input
        type="text"
        value={field.state.value ?? ''}
        onChange={(e) => field.handleChange(e.target.value)}
        inputMode="text"
        placeholder={placeholder}
        disabled={disabled}
      />
      {description && (
        <FieldDescription className="text-right text-xs italic">
          {description}
        </FieldDescription>
      )}
      {errors.length > 0 && <FieldError errors={errors} />}
    </Field>
  )
}
