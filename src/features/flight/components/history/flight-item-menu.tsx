"use client"

import { useState } from "react"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Button } from "@/components/ui/button"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { FormDialogWrapper } from "@/components/form/form-wrapper"
import FlightForm from "@/features/flight/form/flightsForm"
import { useFlightsOptions } from "./flights-options-context"
import { useFlightsData } from "./flights-data-context"
import { useFlightFormAdapter } from "@/features/flight/hooks/use-flight-form-adapter"
import { MoreVertical, Pencil, Trash2, Loader2 } from "lucide-react"
import type { Flight } from "@/features/flight/ui/flight-config"

interface FlightItemMenuProps {
  flight: Flight
}

export function FlightItemMenu({ flight }: FlightItemMenuProps) {
  const [dropdownOpen, setDropdownOpen] = useState(false)
  const [editing, setEditing] = useState(false)
  const [confirming, setConfirming] = useState(false)
  const {
    actions: { deleteFlight, triggerRefresh, isDeleting },
  } = useFlightsData()

  const handleEdit = () => {
    setDropdownOpen(false)
    setEditing(true)
  }

  const handleDelete = async () => {
    setConfirming(false)
    await deleteFlight(flight.id)
  }

  return (
    <>
      <DropdownMenu open={dropdownOpen} onOpenChange={setDropdownOpen}>
        <DropdownMenuTrigger
          render={
            <Button
              variant="ghost"
              size="icon"
              className="size-8 shrink-0"
              onClick={(e) => e.stopPropagation()}
            >
              <MoreVertical className="size-4 text-muted-foreground" />
            </Button>
          }
        ></DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-full">
          <DropdownMenuItem onClick={handleEdit}>
            <Pencil className="size-4" />
            Edit Flight
          </DropdownMenuItem>
          <DropdownMenuItem
            variant="destructive"
            onClick={() => {
              setDropdownOpen(false)
              setConfirming(true)
            }}
            disabled={isDeleting}
          >
            {isDeleting ? (
              <Loader2 className="size-4 animate-spin" />
            ) : (
              <Trash2 className="size-4" />
            )}
            {isDeleting ? "Deleting..." : "Delete Flight"}
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>

      <AlertDialog open={confirming} onOpenChange={setConfirming}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirmation</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete this flight? This action cannot be
              undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete}>
              Continue
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <EditFlightDialog
        flight={flight}
        open={editing}
        onClose={() => setEditing(false)}
        onSuccess={() => {
          setEditing(false)
          triggerRefresh()
        }}
      />
    </>
  )
}

function EditFlightDialog({
  flight,
  open,
  onClose,
  onSuccess,
}: {
  flight: Flight
  open: boolean
  onClose: () => void
  onSuccess: () => void
}) {
  const { airlineFormOptions, aircraftFormOptions, airportFormOptions } =
    useFlightsOptions()

  const flightToFormData = useFlightFormAdapter({
    airlineFormOptions,
    aircraftFormOptions,
    airportFormOptions,
  })

  return (
    <FormDialogWrapper
      open={open}
      onOpenChange={(isOpen) => {
        if (!isOpen) onClose()
      }}
      title="Edit Flight"
      subtitle="Update flight details"
      onSuccess={onSuccess}
      FormComponent={(props) => (
        <FlightForm
          {...props}
          airlineOptions={airlineFormOptions}
          aircraftOptions={aircraftFormOptions}
          airportOptions={airportFormOptions}
          initialData={flightToFormData(flight) as Record<string, unknown>}
          flightId={flight.id}
        />
      )}
    />
  )
}
