import { createFileRoute } from '@tanstack/react-router'
import type { TicketClass } from '@/features/flight/types'
import { TICKET_CLASS } from '@/features/flight/config'
import { HistoryPage } from '@/features/flight/components/history/history-page'
import z from 'zod'

const ticketClassKeys = Object.keys(TICKET_CLASS) as [TicketClass, ...TicketClass[]]

const historySearchSchema = z.object({
  year: z.number().int().optional(),
  airline: z.string().optional(),
  ticketClass: z.enum(ticketClassKeys).optional(),
  search: z.string().optional(),
})

export const Route = createFileRoute('/_protected/flight/history')({
  validateSearch: historySearchSchema,
  component: HistoryPage,
})
