import { useMemo } from 'react'
import { endOfDay, parse, startOfDay, subMonths } from 'date-fns'
import { EVENT_DATE_KEY, TIME_PRESET } from '@/features/fund/config'
import type { TimePresets } from '@/features/fund/config'

interface EventDateRangeSearch {
  period: TimePresets
  from?: string
  to?: string
}

/**
 * Derives the effective date window from the events URL search. Presets compute a
 * rolling range relative to now; custom uses the from/to date keys. Returns Date
 * objects for the picker plus ISO bounds for the RPC query args.
 */
export function useEventDateRange({ period, from, to }: EventDateRangeSearch) {
  return useMemo(() => {
    const now = new Date()

    if (period !== 'custom') {
      const displayFrom = subMonths(now, TIME_PRESET[period].range)

      return {
        displayFrom,
        displayTo: now,
        startISO: startOfDay(displayFrom).toISOString(),
        endISO: endOfDay(now).toISOString(),
      }
    }

    const displayFrom = from
      ? parse(from, EVENT_DATE_KEY, new Date())
      : subMonths(now, TIME_PRESET.M3.range)

    const displayTo = to ? parse(to, EVENT_DATE_KEY, new Date()) : now

    return {
      displayFrom,
      displayTo,
      startISO: startOfDay(displayFrom).toISOString(),
      endISO: endOfDay(displayTo).toISOString(),
    }
  }, [period, from, to])
}
