"use client"

import { useQueryClient } from "@tanstack/react-query"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { PlusIcon } from "lucide-react"
import { useAddEvent } from "./add-event-context"
import { eventKeys } from "@/features/fund/queries/events"
import { dashboardKeys } from "@/features/fund/queries/dashboard"
import { performanceKeys } from "@/features/fund/queries/performance"

export function AddEventSection() {
  const queryClient = useQueryClient()
  const {
    state: { currentConfig },
    actions: { openForm },
  } = useAddEvent()

  const handleSuccess = () => {
    queryClient.invalidateQueries({ queryKey: eventKeys.all })
    queryClient.invalidateQueries({ queryKey: dashboardKeys.all })
    queryClient.invalidateQueries({ queryKey: performanceKeys.all })
  }

  if (!currentConfig) return null

  const { Component } = currentConfig

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger
          render={
            <Button>
              <PlusIcon />
              Add Event
            </Button>
          }
        ></DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-[180px]">
          <DropdownMenuItem onClick={() => openForm("stock")}>
            Stock Event
          </DropdownMenuItem>
          <DropdownMenuItem onClick={() => openForm("cashflow")}>
            Cashflow Event
          </DropdownMenuItem>
          <DropdownMenuItem onClick={() => openForm("borrow")}>
            Borrow Event
          </DropdownMenuItem>
          <DropdownMenuItem onClick={() => openForm("repay")}>
            Repay Event
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
      <Component onSuccess={handleSuccess} />
    </>
  )
}
