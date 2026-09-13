import { createFileRoute } from '@tanstack/react-router'
import type { FlightScope } from '@/features/flight/types'
import { FLIGHT_SCOPE } from '@/features/flight/config'
import { HistoryPage } from '@/features/flight/components/history/history-page'
import z from 'zod'

const scopeKeys = Object.keys(FLIGHT_SCOPE) as [FlightScope, ...FlightScope[]]

const historySearchSchema = z.object({
  year: z.number().int().optional(),
  airline: z.string().optional(),
  scope: z.enum(scopeKeys).optional(),
  search: z.string().optional(),
})

export const Route = createFileRoute('/_protected/flight/history')({
  validateSearch: historySearchSchema,
  component: HistoryPage,
})
