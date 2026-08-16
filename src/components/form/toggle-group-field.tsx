import type { LucideIcon } from "lucide-react"
import type { AnyFieldApi } from "@tanstack/react-form"
import { Field, FieldLabel, FieldError } from "@/components/ui/field"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import { toFieldErrorMessages } from "./field-errors"

interface ToggleOption {
  key: string
  label: string
  icon?: LucideIcon
}

interface ToggleGroupFieldProps {
  field: AnyFieldApi
  options: ToggleOption[]
  disabled?: boolean
}

export function ToggleGroupField({
  field,
  options,
  disabled,
}: ToggleGroupFieldProps) {
  const errors = toFieldErrorMessages(field.state.meta.errors)

  return (
    <Field data-invalid={errors.length > 0} data-disabled={disabled}>
      <FieldLabel className="sr-only">{field.name}</FieldLabel>
      <ToggleGroup
        value={field.state.value ? [field.state.value] : []}
        onValueChange={(value) => {
          if (value.length > 0) field.handleChange(value[0])
        }}
        variant="outline"
        disabled={disabled}
        spacing={0}
        className="w-full"
      >
        {options.map((option) => (
          <ToggleGroupItem
            key={option.key}
            value={option.key}
            className="flex-1"
          >
            {option.icon && <option.icon />}
            {option.label}
          </ToggleGroupItem>
        ))}
      </ToggleGroup>

      {errors.length > 0 && <FieldError errors={errors} />}
    </Field>
  )
}
