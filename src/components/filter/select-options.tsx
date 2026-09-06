import type { LucideIcon } from 'lucide-react'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
} from '@/components/ui/select'
import { Field } from '@/components/ui/field'

interface FilterSelectOption {
  label: string
  icon?: LucideIcon
}

interface Props {
  icon?: LucideIcon
  placeholder: string
  value: string | null
  onValueChange: (value: string) => void
  options: Record<string, FilterSelectOption>
  /** Explicit display order. Needed because integer-like keys are sorted ascending by JS, e.g. years. */
  optionsOrder?: readonly string[]
  disabled?: boolean
}

export function FilterSelect({
  icon: Icon,
  placeholder,
  value,
  onValueChange,
  options,
  optionsOrder,
  disabled,
}: Props) {
  const optionByKey = new Map(Object.entries(options))
  const keys = optionsOrder ?? Object.keys(options)
  const selectedOption = value !== null ? optionByKey.get(value) : null

  return (
    <Field orientation="horizontal" className="min-w-50">
      <Select
        value={value}
        onValueChange={(v) => {
          if (v !== null) {
            onValueChange(v)
          }
        }}
        disabled={disabled}
      >
        <SelectTrigger className="w-full">
          {Icon && <Icon />}
          <span className="flex-1 text-left">
            {selectedOption?.label ?? placeholder}
          </span>
        </SelectTrigger>

        <SelectContent alignItemWithTrigger={false}>
          {keys.map((key) => {
            const option = optionByKey.get(key)
            if (!option) return null
            const OptionIcon = option.icon

            return (
              <SelectItem key={key} value={key}>
                {OptionIcon && <OptionIcon />}
                {option.label}
              </SelectItem>
            )
          })}
        </SelectContent>
      </Select>
    </Field>
  )
}
