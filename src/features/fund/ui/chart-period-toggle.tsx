import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'

interface ChartPeriodToggleProps {
  value: string
  onChange: (value: string) => void
  options: { value: string; label: string }[]
}

export function ChartPeriodToggle({
  value,
  onChange,
  options,
}: ChartPeriodToggleProps) {
  return (
    <ToggleGroup
      value={[value]}
      onValueChange={(values) => {
        if (values.length > 0) onChange(values[0])
      }}
      spacing={0}
      className="w-full"
      variant="outline"
    >
      {options.map(({ value, label }) => (
        <ToggleGroupItem key={value} value={value} className="flex-1">
          {label}
        </ToggleGroupItem>
      ))}
    </ToggleGroup>
  )
}
