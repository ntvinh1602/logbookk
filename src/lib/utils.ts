import { clsx, type ClassValue } from 'clsx'
import { fromZonedTime } from 'date-fns-tz'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
// --- Cached Intl.NumberFormat instances ---
// Creating Intl.NumberFormat is expensive — cache by config key to avoid
// re-instantiating on every call (these are called on every render tick).

const numberFormatters = [
  new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }),
  new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  }),
  new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }),
]

const compactFormatter = [
  new Intl.NumberFormat('en-US', {
    notation: 'compact',
    maximumSignificantDigits: 3,
    compactDisplay: 'short',
  }),
  new Intl.NumberFormat('en-US', {
    notation: 'compact',
    maximumSignificantDigits: 4,
    compactDisplay: 'short',
  }),
]

const percentageFormatter = new Intl.NumberFormat('en-US', {
  style: 'percent',
  minimumFractionDigits: 1,
  maximumFractionDigits: 1,
})

// Format number based decimal places
export function formatNum(amount: number, fractionDigits: 0 | 1 | 2 = 0) {
  return numberFormatters[fractionDigits].format(amount)
}

// Compact number format (10K, 10M etc.)
export function compactNum(amount: number, significant: 3 | 4 = 3) {
  return compactFormatter[significant - 3].format(amount)
}

// Percentage number format
export function pctNum(amount: number) {
  return percentageFormatter.format(amount)
}

/**
 * Interprets a naive local datetime ("yyyy-MM-ddTHH:mm") as wall-clock time in
 * the airport's IANA timezone and converts it to a UTC ISO string.
 */
export function localToUtc(local: string, timeZone: string) {
  return fromZonedTime(local, timeZone).toISOString()
}