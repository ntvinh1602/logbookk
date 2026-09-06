import type { LucideIcon } from 'lucide-react'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectGroup,
  SelectSeparator,
} from '@/components/ui/select'
import { Field } from '@/components/ui/field'

interface FilterSelectOption {
  label: string
  icon?: LucideIcon
}

interface SelectAllEnabledProps {
  icon?: LucideIcon
  placeholder: string
  value: string | null
  onValueChange: (value: string | null) => void
  allLabel: string
  options: Record<string, FilterSelectOption>
  /** Explicit display order. Needed because integer-like keys are sorted ascending by JS, e.g. years. */
  optionsOrder?: readonly string[]
  disabled?: boolean
}

interface SingleOptionSelectProps {
  icon?: LucideIcon
  placeholder: string
  value: string
  onValueChange: (value: string) => void
  options: Record<string, FilterSelectOption>
  /** Explicit display order. Needed because integer-like keys are sorted ascending by JS, e.g. years. */
  optionsOrder?: readonly string[]
  disabled?: boolean
}

export function SelectAllEnabled({
  icon: Icon,
  placeholder,
  value,
  onValueChange,
  allLabel,
  options,
  optionsOrder,
  disabled,
}: SelectAllEnabledProps) {
  const optionByKey = new Map(Object.entries(options))
  const keys = optionsOrder ?? Object.keys(options)

  const selectedLabel =
    value === null ? allLabel : (optionByKey.get(value)?.label ?? placeholder)

  return (
    <Field orientation="horizontal" className="min-w-50">
      <Select
        value={value ?? 'all'}
        onValueChange={(v) => {
          if (v !== null) {
            onValueChange(v === 'all' ? null : v)
          }
        }}
        disabled={disabled}
      >
        <SelectTrigger className="w-full">
          {Icon && <Icon />}
          <span className="flex-1 text-left">
            {selectedLabel}
          </span>
        </SelectTrigger>

        <SelectContent alignItemWithTrigger={false}>
          <SelectGroup>
            <SelectItem value="all">
              {allLabel}
            </SelectItem>
          </SelectGroup>

          <SelectSeparator />

          <SelectGroup>
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
          </SelectGroup>
        </SelectContent>
      </Select>
    </Field>
  )
}

export function SingleOptionSelect({
  icon: Icon,
  placeholder,
  value,
  onValueChange,
  options,
  optionsOrder,
  disabled,
}: SingleOptionSelectProps) {
  const optionByKey = new Map(Object.entries(options))
  const keys = optionsOrder ?? Object.keys(options)
  const selectedOption = optionByKey.get(value)

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
