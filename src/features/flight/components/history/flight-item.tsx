import {
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from '@/components/ui/accordion'
import {
  Item,
  ItemGroup,
  ItemMedia,
  ItemContent,
  ItemTitle,
  ItemDescription,
  ItemSeparator,
} from '@/components/ui/item'
import { Badge } from '@/components/ui/badge'
import {
  Plane,
  Calendar,
  Clock,
  ChevronRight,
  Users,
  Armchair,
  Star,
  Hash,
  Leaf,
  BriefcaseBusiness,
} from 'lucide-react'
import { formatInTimeZone } from 'date-fns-tz'
import type { Flight } from '@/lib/supabase/api/types'

interface FlightItemProps {
  flight: Flight
  itemKey: string
  menuSlot?: React.ReactNode
}

export const ticketClass = [
  { key: 'eco', label: 'Economy', icon: Leaf },
  { key: 'biz', label: 'Business', icon: BriefcaseBusiness },
]

export const FlightDetail = [
  { key: 'tail', icon: Hash, getValue: (f: Flight) => f.tail_number ?? 'N/A' },
  {
    key: 'airline',
    icon: Users,
    getValue: (f: Flight) => f.airline_name ?? 'N/A',
  },
  {
    key: 'aircraft',
    icon: Plane,
    getValue: (f: Flight) => f.aircraft_type ?? 'N/A',
  },
  {
    key: 'duration',
    icon: Clock,
    getValue: (f: Flight) => f.duration ?? 'N/A',
  },
  {
    key: 'seat',
    icon: Armchair,
    getValue: (f: Flight) =>
      `${f.seat_number ?? 'N/A'} - ${f.seat_position ?? 'N/A'}`,
  },
  {
    key: 'class',
    icon: Star,
    getValue: (f: Flight) =>
      ticketClass.find((s) => s.key === f.ticket_class)?.label ?? 'N/A',
  },
] as const

export function FlightItem({ flight, itemKey, menuSlot }: FlightItemProps) {
  const isUpcoming = new Date(flight.departure_time) > new Date()
  const departureDate = formatInTimeZone(
    flight.departure_time,
    flight.departure_tz,
    'yyyy-MM-dd',
  )
  const departureTime = formatInTimeZone(
    flight.departure_time,
    flight.departure_tz,
    'HH:mm X',
  )
  const arrivalDate = formatInTimeZone(
    flight.arrival_time,
    flight.arrival_tz,
    'yyyy-MM-dd',
  )
  const arrivalTime = formatInTimeZone(
    flight.arrival_time,
    flight.arrival_tz,
    'HH:mm X',
  )
  return (
    <AccordionItem value={itemKey} className="relative">
      <AccordionTrigger className="p-0 border-none hover:no-underline rounded-2xl [&>[data-slot=accordion-trigger-icon]]:hidden!">
        <Item
          variant="default"
          className="cursor-pointer transition-colors hover:bg-accent/50 rounded-none"
        >
          <ItemMedia variant="image" className="hidden sm:block">
            <img
              src={`${import.meta.env.VITE_PUBLIC_SUPABASE_URL}/storage/v1/object/public/logo/airline/${flight.airline_logo}`}
              alt=""
              width={44}
              height={44}
            />
          </ItemMedia>
          <ItemSeparator orientation="vertical" className="hidden sm:block" />
          <ItemContent>
            <div className="flex gap-2">
              <Badge variant="secondary" className="hidden sm:block">
                {flight.departure_code}
              </Badge>
              <ItemTitle>{flight.departure_name}</ItemTitle>
            </div>
            <ItemDescription className="-ml-2">
              <Badge variant="ghost" className="pointer-events-none">
                <Calendar />
                {departureDate}
              </Badge>
              <Badge variant="ghost" className="pointer-events-none">
                <Clock />
                {departureTime}
              </Badge>
            </ItemDescription>
          </ItemContent>
          <ItemMedia className="flex-col">
            {isUpcoming ? (
              <Badge variant="secondary">Scheduled</Badge>
            ) : (
              <Plane className="size-4 rotate-45 text-muted-foreground" />
            )}
            <ItemDescription className="text-xs">
              {flight.flight_number}
            </ItemDescription>
          </ItemMedia>
          <ItemContent className="items-end">
            <div className="flex gap-2">
              <ItemTitle>{flight.arrival_name}</ItemTitle>
              <Badge variant="secondary" className="hidden sm:block">
                {flight.arrival_code}
              </Badge>
            </div>
            <ItemDescription className="-mr-2 text-right">
              <Badge variant="ghost" className="pointer-events-none">
                <Calendar />
                {arrivalDate}
              </Badge>
              <Badge variant="ghost" className="pointer-events-none">
                <Clock />
                {arrivalTime}
              </Badge>
            </ItemDescription>
          </ItemContent>
          <ItemSeparator orientation="vertical" className="hidden sm:block" />
          <ChevronRight
            data-slot="accordion-trigger-icon"
            className="group-aria-expanded/accordion-trigger:rotate-90 transition-transform duration-200 hidden sm:block"
          />
        </Item>
      </AccordionTrigger>
      <AccordionContent className="h-full flex items-center border-t border-border pt-4">
        <ItemGroup className="grid grid-cols-2 sm:grid-cols-3 gap-2">
          {FlightDetail.map((detail) => {
            const value = detail.getValue(flight)
            if (!value) return null
            return (
              <Item
                key={detail.key}
                size="xs"
                className="p-1"
                variant="default"
              >
                <ItemMedia variant="icon" className="text-muted-foreground">
                  <detail.icon />
                </ItemMedia>
                <ItemContent>
                  <ItemDescription className="capitalize">
                    {value}
                  </ItemDescription>
                </ItemContent>
              </Item>
            )
          })}
        </ItemGroup>
        {menuSlot}
      </AccordionContent>
    </AccordionItem>
  )
}
