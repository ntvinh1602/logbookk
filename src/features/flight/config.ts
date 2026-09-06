import type { FlightsSummaryRow, StatsRow } from '@/features/flight/types'
import { formatNum } from '@/lib/utils'
import {
  BriefcaseBusiness,
  Leaf,
  Users,
  Armchair,
  Star,
  Hash,
  Plane,
  Clock,
  TicketsPlane,
  PlaneTakeoff,
  Earth,
  Route,
} from 'lucide-react'

export const FLIGHTS_START_YEAR = 2019

export const TICKET_CLASS = {
  eco: {
    label: 'Economy',
    icon: Leaf,
  },
  biz: {
    label: 'Business',
    icon: BriefcaseBusiness,
  },
}

export const SEAT_POSITIONS = {
  window: {
    label: 'Window',
  },
  middle: {
    label: 'Middle',
  },
  aisle: {
    label: 'Aisle',
  },
}

export const FLIGHT_DETAILS = [
  {
    key: 'tail',
    icon: Hash,
    getValue: (f: FlightsSummaryRow) => f.tail_number,
  },
  {
    key: 'airline',
    icon: Users,
    getValue: (f: FlightsSummaryRow) => f.airline_name,
  },
  {
    key: 'aircraft',
    icon: Plane,
    getValue: (f: FlightsSummaryRow) => f.aircraft_type,
  },
  {
    key: 'duration',
    icon: Clock,
    getValue: (f: FlightsSummaryRow) => f.duration,
  },
  {
    key: 'seat',
    icon: Armchair,
    getValue: (f: FlightsSummaryRow) => `${f.seat_number} - ${f.seat_position}`,
  },
  {
    key: 'class',
    icon: Star,
    getValue: (f: FlightsSummaryRow) => TICKET_CLASS[f.ticket_class]?.label,
  },
]

export const FLIGHTS_STATS = [
  {
    label: 'Flights',
    icon: TicketsPlane,
    getValue: (s: StatsRow) => s.flights_count,
  },
  {
    label: 'Airports',
    icon: PlaneTakeoff,
    getValue: (s: StatsRow) => s.airports_count,
  },
  {
    label: 'Countries',
    icon: Earth,
    getValue: (s: StatsRow) => s.country_count,
  },
  {
    label: 'Aircraft Types',
    icon: Plane,
    getValue: (s: StatsRow) => s.type_count,
  },
  {
    label: 'Distance',
    icon: Route,
    getValue: (s: StatsRow) => `${formatNum(s.total_distance)} km`,
  },
  {
    label: 'Duration',
    icon: Clock,
    getValue: (s: StatsRow) => `${s.total_duration} hours`,
  },
]
