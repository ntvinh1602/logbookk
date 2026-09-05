import type { TicketClass } from '@/lib/supabase/api/types'

export interface FilterState {
  year: string | null // "all" or a year string like "2024"
  airline: string | null // "all" or an airline name
  ticketClass: TicketClass // selected seat type value
  search: string // flight number search
}
