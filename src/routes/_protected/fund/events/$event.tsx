import { createFileRoute } from '@tanstack/react-router'
import { DEFAULT_TIME_PRESET, TIME_PRESET } from '@/features/fund/config'
import type { TimePresets } from '@/features/fund/config'
import { EventsPage } from '@/features/fund/components/events/events-page'
import z from 'zod'

/* ---------- search schema ---------- */

const presetKeys = Object.keys(TIME_PRESET) as [TimePresets, ...TimePresets[]]

const eventsSearchSchema = z.object({
  period: z.enum(presetKeys).default(DEFAULT_TIME_PRESET),
  from: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional(),
  to: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional(),
  op: z.string().optional(),
})

export const Route = createFileRoute('/_protected/fund/events/$event')({
  validateSearch: eventsSearchSchema,
  component: EventsPage,
})
