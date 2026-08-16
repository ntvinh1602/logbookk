import * as React from "react"
import { useForm } from "@tanstack/react-form"
import { toast } from "sonner"
import { AddFlight } from "@/features/flight/actions/add-flight"
import { EditFlight } from "@/features/flight/actions/edit-flight"
import { TextField } from "@/components/form/text-field"
import { SelectField } from "@/components/form/select-field"
import { ComboboxField } from "@/components/form/combobox-field"
import { DateTimeField } from "@/components/form/datetime-field"
import { FieldGroup, FieldTitle } from "@/components/ui/field"
import { flightSchema, type FlightFormValues } from "./schema"
import { ticketClass } from "@/features/flight/ui/flight-config"
import { ToggleGroupField } from "@/components/form/toggle-group-field"

interface FlightFormProps {
  onSuccess?: () => void
  formId: string
  onLoadingChange: (loading: boolean) => void
  resetFormRef: { current: () => void }
  airlineOptions: { value: string; label: string }[]
  aircraftOptions: { value: string; label: string }[]
  airportOptions: { value: string; label: string }[]
  initialData?: Partial<FlightFormValues>
  flightId?: string
}

export default function FlightForm({
  onSuccess,
  formId,
  onLoadingChange,
  resetFormRef,
  airlineOptions,
  aircraftOptions,
  airportOptions,
  initialData,
  flightId,
}: FlightFormProps) {
  const form = useForm({
    defaultValues: {
      departureAirportId: initialData?.departureAirportId ?? "",
      departureTimeLocal: initialData?.departureTimeLocal ?? "",
      arrivalAirportId: initialData?.arrivalAirportId ?? "",
      arrivalTimeLocal: initialData?.arrivalTimeLocal ?? "",
      flightNumber: initialData?.flightNumber ?? "",
      airlineId: initialData?.airlineId ?? "",
      ticketClass: initialData?.ticketClass ?? "eco",
      seatNo: initialData?.seatNo ?? null,
      seatPos: initialData?.seatPos ?? null,
      aircraftId: initialData?.aircraftId ?? null,
      tailNo: initialData?.tailNo ?? null,
      notes: initialData?.notes ?? null,
    },
    validators: {
      // Cross-field check (lives outside the per-field zod schemas)
      onChange: ({ value }) => {
        if (
          value.departureAirportId &&
          value.arrivalAirportId &&
          value.departureAirportId === value.arrivalAirportId
        ) {
          return {
            fields: {
              arrivalAirportId: "Departure and arrival airports must differ",
            },
          }
        }
        return undefined
      },
    },
    onSubmit: async ({ value }) => {
      onLoadingChange(true)

      try {
        // Apply zod transforms (uppercase flight number, "" -> null)
        const values = flightSchema.parse(value)

        if (flightId) {
          await EditFlight(flightId, values)
          toast.success("Flight updated successfully", {
            description: `Flight number ${values.flightNumber} updated`,
          })
        } else {
          await AddFlight(values)
          toast.success("Flight added successfully", {
            description: `Flight number ${values.flightNumber} created`,
          })
        }

        form.reset()
        onSuccess?.()
      } catch (err: unknown) {
        let message = "Unexpected database error"

        if (err instanceof Error) {
          message = err.message
        } else if (
          typeof err === "object" &&
          err !== null &&
          "message" in err &&
          typeof (err as { message: unknown }).message === "string"
        ) {
          message = (err as { message: string }).message
        }

        toast.error(flightId ? "Failed to update flight" : "Failed to create flight", {
          description: message,
        })
      } finally {
        onLoadingChange(false)
      }
    },
  })

  React.useEffect(() => {
    resetFormRef.current = () => form.reset()
  }, [form, resetFormRef])

  return (
    <form
      id={formId}
      noValidate
      onSubmit={(e) => {
        e.preventDefault()
        e.stopPropagation()
        void form.handleSubmit()
      }}
    >
      <FieldGroup className="gap-3">
        <FieldTitle>Departure from</FieldTitle>
        <form.Field
          name="departureAirportId"
          validators={{ onChange: flightSchema.shape.departureAirportId }}
        >
          {(field) => (
            <ComboboxField
              field={field}
              items={airportOptions}
              label="Departure Airport"
              placeholder="Departure airport"
              emptyPlaceholder="No airport found"
            />
          )}
        </form.Field>
        <form.Field
          name="departureTimeLocal"
          validators={{ onChange: flightSchema.shape.departureTimeLocal }}
        >
          {(field) => (
            <DateTimeField
              field={field}
              label="Departure (Local Time)"
              placeholder="Departure local time"
            />
          )}
        </form.Field>
        <FieldTitle>Arrive to</FieldTitle>
        <form.Field
          name="arrivalAirportId"
          validators={{ onChange: flightSchema.shape.arrivalAirportId }}
        >
          {(field) => (
            <ComboboxField
              field={field}
              items={airportOptions}
              label="Arrival Airport"
              placeholder="Arrival airport"
              emptyPlaceholder="No airport found"
            />
          )}
        </form.Field>
        <form.Field
          name="arrivalTimeLocal"
          validators={{ onChange: flightSchema.shape.arrivalTimeLocal }}
        >
          {(field) => (
            <DateTimeField
              field={field}
              label="Arrival (Local Time)"
              placeholder="Arrival local time"
            />
          )}
        </form.Field>
        <FieldTitle>Flight Details</FieldTitle>
        <form.Field
          name="flightNumber"
          validators={{ onChange: flightSchema.shape.flightNumber }}
        >
          {(field) => (
            <TextField
              field={field}
              label="Flight Number"
              placeholder="Flight number"
            />
          )}
        </form.Field>
        <form.Field
          name="airlineId"
          validators={{ onChange: flightSchema.shape.airlineId }}
        >
          {(field) => (
            <SelectField
              field={field}
              options={airlineOptions}
              label="Airline"
              placeholder="Airlines"
            />
          )}
        </form.Field>
        <form.Field
          name="ticketClass"
          validators={{ onChange: flightSchema.shape.ticketClass }}
        >
          {(field) => (
            <ToggleGroupField field={field} options={ticketClass} />
          )}
        </form.Field>
        <form.Field
          name="seatNo"
          validators={{ onChange: flightSchema.shape.seatNo }}
        >
          {(field) => (
            <TextField
              field={field}
              label="Seat Number"
              placeholder="Seat number"
            />
          )}
        </form.Field>
        <form.Field
          name="seatPos"
          validators={{ onChange: flightSchema.shape.seatPos }}
        >
          {(field) => (
            <ToggleGroupField
              field={field}
              options={[
                { key: "window", label: "Window" },
                { key: "middle", label: "Middle" },
                { key: "aisle", label: "Aisle" },
              ]}
            />
          )}
        </form.Field>
        <form.Field
          name="aircraftId"
          validators={{ onChange: flightSchema.shape.aircraftId }}
        >
          {(field) => (
            <SelectField
              field={field}
              options={aircraftOptions}
              label="Aircraft"
              placeholder="Aircraft type"
            />
          )}
        </form.Field>
        <form.Field
          name="tailNo"
          validators={{ onChange: flightSchema.shape.tailNo }}
        >
          {(field) => (
            <TextField
              field={field}
              label="Tail Number"
              placeholder="Aircraft registration"
            />
          )}
        </form.Field>
        <form.Field
          name="notes"
          validators={{ onChange: flightSchema.shape.notes }}
        >
          {(field) => (
            <TextField field={field} label="Notes" placeholder="Notes" />
          )}
        </form.Field>
      </FieldGroup>
    </form>
  )
}
