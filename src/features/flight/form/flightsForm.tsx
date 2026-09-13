import { useId, useMemo, useState } from 'react'
import { useSelector, useForm } from '@tanstack/react-form'
import { useQuery } from '@tanstack/react-query'
import { toast } from 'sonner'
import { PlusIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  Sheet,
  SheetTrigger,
  SheetContent,
  SheetHeader,
  SheetDescription,
  SheetFooter,
  SheetTitle,
} from '@/components/ui/sheet'
import { TextField } from '@/components/form/text-field'
import { SelectField } from '@/components/form/select-field'
import { ComboboxField } from '@/components/form/combobox-field'
import { DateTimeField } from '@/components/form/datetime-field'
import { Field, FieldGroup } from '@/components/ui/field'
import { flightSchema } from '@/features/flight/form/schema'
import type { FlightFormValues } from '@/features/flight/form/schema'
import { ToggleGroupField } from '@/components/form/toggle-group-field'
import { flights } from '@/features/flight/queries/flights'
import { useAddFlight } from '@/features/flight/hooks/use-add-flight'
import { useUpdateFlight } from '@/features/flight/hooks/use-update-flight'
import { useFlightFormOptions } from '@/features/flight/hooks/use-flight-form-options'
import { useFlightFormAdapter } from '@/features/flight/hooks/use-flight-form-adapter'
import type {
  FlightsSummaryRow,
  FlightUpsertInput,
  SeatPosition,
} from '@/features/flight/types'
import { SEAT_POSITIONS, TICKET_CLASS } from '@/features/flight/config'

function toFlightUpsert(
  values: FlightFormValues,
  timezoneByCode: Map<string, string>,
): FlightUpsertInput {
  const departureTz = timezoneByCode.get(values.departureCode)
  if (!departureTz) {
    throw new Error('Departure airport timezone not found')
  }
  const arrivalTz = timezoneByCode.get(values.arrivalCode)
  if (!arrivalTz) {
    throw new Error('Arrival airport timezone not found')
  }

  return {
    airlineCode: values.airlineCode,
    departureCode: values.departureCode,
    departureLocal: values.departureTimeLocal,
    departureTz,
    arrivalCode: values.arrivalCode,
    arrivalLocal: values.arrivalTimeLocal,
    arrivalTz,
    flightNumber: values.flightNumber,
    ticketClass: values.ticketClass,
    aircraftType: values.aircraftCode,
    seatNumber: values.seatNo,
    seatPosition: values.seatPos as SeatPosition | null,
    tailNumber: values.tailNo,
  }
}

type FlightFormOptions = ReturnType<typeof useFlightFormOptions>

interface FlightDialogProps {
  onOpenChange: (open: boolean) => void
  title: string
  subtitle?: string
  options: FlightFormOptions
  flight?: FlightsSummaryRow
}

/**
 * Shared dialog shell for add & edit: owns the Sheet content, the form, the
 * Reset/Submit footer and validation. Mounted only while the Sheet is open, so
 * defaultValues are (re)captured from the current flight on every open.
 */
function FlightDialog({
  onOpenChange,
  title,
  subtitle,
  options,
  flight,
}: FlightDialogProps) {
  const formId = useId()
  const { addFlight } = useAddFlight()
  const { updateFlight } = useUpdateFlight()

  const flightToFormData = useFlightFormAdapter({
    airlineFormOptions: options.airlineFormOptions,
    aircraftFormOptions: options.aircraftFormOptions,
  })

  const initialData = flight ? flightToFormData(flight) : undefined

  // Cached by react-query (the options already fetch airports for the pickers),
  // used here only to resolve an airport's IANA timezone for time conversion.
  const airportsQuery = useQuery(flights.airports())
  const timezoneByCode = useMemo(() => {
    const map = new Map<string, string>()
    for (const airport of airportsQuery.data ?? []) {
      if (airport.timezone) map.set(airport.iata_code, airport.timezone)
    }
    return map
  }, [airportsQuery.data])

  const form = useForm({
    defaultValues: {
      departureCode: initialData?.departureCode ?? '',
      departureTimeLocal: initialData?.departureTimeLocal ?? '',
      arrivalCode: initialData?.arrivalCode ?? '',
      arrivalTimeLocal: initialData?.arrivalTimeLocal ?? '',
      flightNumber: initialData?.flightNumber ?? '',
      airlineCode: initialData?.airlineCode ?? '',
      ticketClass: initialData?.ticketClass ?? 'eco',
      seatNo: initialData?.seatNo ?? null,
      seatPos: initialData?.seatPos ?? null,
      aircraftCode: initialData?.aircraftCode ?? null,
      tailNo: initialData?.tailNo ?? null,
    },
    validators: {
      onSubmit: flightSchema,
    },
    onSubmit: async ({ value }) => {
      let payload: FlightUpsertInput

      try {
        const values = flightSchema.parse(value)
        payload = toFlightUpsert(values, timezoneByCode)
      } catch (err: unknown) {
        toast.error(
          'Unable to save flight',
          err instanceof Error ? { description: err.message } : undefined,
        )
        return
      }

      try {
        if (flight) await updateFlight(flight.id, payload)
        else await addFlight(payload)
      } catch {
        // Error toast is handled by the mutation hook; keep the dialog open.
        return
      }

      form.reset()
      onOpenChange(false)
    },
  })

  const isSubmitting = useSelector(form.store, (state) => state.isSubmitting)

  return (
    <SheetContent>
      <SheetHeader>
        <SheetTitle>{title}</SheetTitle>
        {subtitle && <SheetDescription>{subtitle}</SheetDescription>}
      </SheetHeader>
      <form
        id={formId}
        noValidate
        className="min-h-0 flex-1 overflow-y-auto"
        onSubmit={(e) => {
          e.preventDefault()
          e.stopPropagation()
          void form.handleSubmit()
        }}
      >
        <Tabs className="px-4 gap-6">
          <TabsList>
            <TabsTrigger value="flight">Flight Details</TabsTrigger>
            <TabsTrigger value="ticket">Ticket Details</TabsTrigger>
          </TabsList>
          <TabsContent value="flight">
            <FieldGroup>
              <form.Field name="departureCode">
                {(field) => (
                  <ComboboxField
                    field={field}
                    items={options.airportFormOptions}
                    label="From"
                    placeholder="Select airport"
                    emptyPlaceholder="No airport found"
                  />
                )}
              </form.Field>
              <form.Field name="departureTimeLocal">
                {(field) => (
                  <DateTimeField
                    field={field}
                    label="Departure Time"
                    placeholder="Select date & time"
                  />
                )}
              </form.Field>
              <form.Field name="arrivalCode">
                {(field) => (
                  <ComboboxField
                    field={field}
                    items={options.airportFormOptions}
                    label="To"
                    placeholder="Select airport"
                    emptyPlaceholder="No airport found"
                  />
                )}
              </form.Field>
              <form.Field name="arrivalTimeLocal">
                {(field) => (
                  <DateTimeField
                    field={field}
                    label="Arrival Time"
                    placeholder="Select date & time"
                  />
                )}
              </form.Field>
              <form.Field name="flightNumber">
                {(field) => (
                  <TextField
                    field={field}
                    label="Flight Number"
                    placeholder="Input flight number"
                  />
                )}
              </form.Field>
              <form.Field name="airlineCode">
                {(field) => (
                  <SelectField
                    field={field}
                    options={options.airlineFormOptions}
                    label="Airline"
                    placeholder="Select airlines"
                  />
                )}
              </form.Field>
              <form.Field name="aircraftCode">
                {(field) => (
                  <SelectField
                    field={field}
                    options={options.aircraftFormOptions}
                    label="Aircraft"
                    placeholder="Select aircraft type"
                    description="Optional"
                  />
                )}
              </form.Field>
              <form.Field name="tailNo">
                {(field) => (
                  <TextField
                    field={field}
                    label="Tail Number"
                    placeholder="Input aircraft reg."
                    description="Optional"
                  />
                )}
              </form.Field>
            </FieldGroup>
          </TabsContent>

          <TabsContent value="ticket">
            <FieldGroup>
              <form.Field name="ticketClass">
                {(field) => (
                  <ToggleGroupField
                    field={field}
                    label="Ticket Class"
                    options={TICKET_CLASS}
                  />
                )}
              </form.Field>

              <form.Field name="seatNo">
                {(field) => (
                  <TextField
                    field={field}
                    label="Seat Number"
                    placeholder="Input seat number"
                    description="Optional"
                  />
                )}
              </form.Field>
              <form.Field name="seatPos">
                {(field) => (
                  <ToggleGroupField
                    field={field}
                    label="Seat Position"
                    options={SEAT_POSITIONS}
                    description="Optional"
                  />
                )}
              </form.Field>
            </FieldGroup>
          </TabsContent>
        </Tabs>
      </form>
      <SheetFooter>
        <Field>
          <Button type="button" variant="outline" onClick={() => form.reset()}>
            Reset
          </Button>
          <Button type="submit" form={formId} disabled={isSubmitting}>
            {isSubmitting ? 'Submitting...' : 'Submit'}
          </Button>
        </Field>
      </SheetFooter>
    </SheetContent>
  )
}

export function AddFlightForm() {
  const options = useFlightFormOptions()
  const [open, setOpen] = useState(false)

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger
        render={
          <Button>
            <PlusIcon /> Add Flight
          </Button>
        }
      />
      <FlightDialog
        onOpenChange={setOpen}
        title="Add Flight"
        subtitle="Log a new flight into your travel history"
        options={options}
      />
    </Sheet>
  )
}

export function EditFlightForm({
  flight,
  open,
  onOpenChange,
}: {
  flight: FlightsSummaryRow
  open: boolean
  onOpenChange: (open: boolean) => void
}) {
  const options = useFlightFormOptions()

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <FlightDialog
        onOpenChange={onOpenChange}
        title="Edit Flight"
        subtitle="Update flight details"
        options={options}
        flight={flight}
      />
    </Sheet>
  )
}
