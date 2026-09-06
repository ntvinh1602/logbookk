import type { LucideIcon } from 'lucide-react'
import type { AnyFieldApi } from '@tanstack/react-form'
import { Field, FieldError, FieldLabel } from '@/components/ui/field'
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'
import { toFieldErrorMessages } from '@/components/form/field-errors'

interface ToggleOption {
  label: string
  icon?: LucideIcon
}

interface ToggleGroupFieldProps {
  field: AnyFieldApi
  label: string
  options: Record<string, ToggleOption>
  disabled?: boolean
  displayIcon?: boolean
  onValueChange?: (value: string) => void
}

export function ToggleGroupField({
  field,
  label,
  options,
  disabled,
  displayIcon = true,
  onValueChange,
}: ToggleGroupFieldProps) {
  const errors = toFieldErrorMessages(field.state.meta.errors)

  return (
    <Field data-invalid={errors.length > 0} data-disabled={disabled}>
      <FieldLabel>{label}</FieldLabel>
      <ToggleGroup
        value={field.state.value ? [field.state.value] : []}
        onValueChange={(value) => {
          if (value.length > 0) {
            field.handleChange(value[0])
            onValueChange?.(value[0])
          }
        }}
        variant="outline"
        disabled={disabled}
        spacing={0}
        className="w-full"
      >
        {Object.entries(options).map(([key, option]) => {
          const Icon = displayIcon && option.icon

          return (
            <ToggleGroupItem key={key} value={key} className="flex-1">
              {Icon && <Icon />}
              {option.label}
            </ToggleGroupItem>
          )
        })}
      </ToggleGroup>

      {errors.length > 0 && <FieldError errors={errors} />}
    </Field>
  )
}
