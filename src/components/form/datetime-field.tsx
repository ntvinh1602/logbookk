import * as React from "react"
import type { AnyFieldApi } from "@tanstack/react-form"
import { format, parseISO } from "date-fns"
import { Calendar } from "@/components/ui/calendar"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"
import { Button } from "@/components/ui/button"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { CalendarIcon, ClockIcon } from "lucide-react"
import { cn } from "@/lib/utils"
import { toFieldErrorMessages } from "./field-errors"

type DateTimeFieldProps = {
  field: AnyFieldApi
  label: string
  placeholder?: string
}

function formatLocalDateTime(date: Date) {
  if (isNaN(date.getTime())) return ""

  const pad = (n: number) => n.toString().padStart(2, "0")

  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(
    date.getDate(),
  )}T${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(
    date.getSeconds(),
  )}`
}

function formatDisplay(
  dateString?: string,
  placeholder = "Select date & time",
) {
  if (!dateString) return placeholder

  const date = parseISO(dateString)

  if (isNaN(date.getTime())) return placeholder

  return format(date, "dd MMM yyyy, HH:mm")
}

function DateTimePicker({
  field,
  placeholder,
}: {
  field: { value: string; onChange: (value: string) => void }
  placeholder: string
}) {
  const value = field.value ? new Date(field.value) : undefined
  const [time, setTime] = React.useState(
    value ? value.toTimeString().slice(0, 8) : "10:30:00",
  )

  function handleDateChange(date?: Date) {
    if (!date) {
      field.onChange("")
      return
    }

    const [h, m, s] = time.split(":").map(Number)

    const updated = new Date(date)
    updated.setHours(h, m, s)

    field.onChange(formatLocalDateTime(updated))
  }

  function handleTimeChange(e: React.ChangeEvent<HTMLInputElement>) {
    const newTime = e.target.value
    setTime(newTime)

    if (!value) return

    const [h, m, s] = newTime.split(":").map(Number)

    const updated = new Date(value)
    updated.setHours(h, m, s)

    field.onChange(formatLocalDateTime(updated))
  }

  return (
    <Popover>
      <PopoverTrigger
        render={
          <Button
            type="button"
            variant="outline"
            className={cn(
              "justify-between",
              !field.value && "text-muted-foreground",
            )}
          >
            {formatDisplay(field.value, placeholder)}
            <CalendarIcon />
          </Button>
        }
      ></PopoverTrigger>

      <PopoverContent className="w-auto p-0" align="center">
        <Calendar
          mode="single"
          captionLayout="dropdown"
          weekStartsOn={1}
          defaultMonth={value}
          selected={value}
          onSelect={handleDateChange}
        />

        <div className="flex items-center gap-2 px-4 pb-2">
          <ClockIcon className="stroke-1" />
          <Input
            type="time"
            step="1"
            value={time}
            onChange={handleTimeChange}
          />
        </div>
      </PopoverContent>
    </Popover>
  )
}

export function DateTimeField({
  field,
  label,
  placeholder = "Select date & time",
}: DateTimeFieldProps) {
  const errors = toFieldErrorMessages(field.state.meta.errors)

  return (
    <Field data-invalid={errors.length > 0}>
      <FieldLabel className="sr-only">{label}</FieldLabel>
      <DateTimePicker
        field={{
          value: field.state.value ?? "",
          onChange: (value) => field.handleChange(value),
        }}
        placeholder={placeholder}
      />
      {errors.length > 0 && <FieldError errors={errors} />}
    </Field>
  )
}
