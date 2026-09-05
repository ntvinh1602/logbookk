import * as z from 'zod'

export const ticketClassSchema = z.enum(['eco', 'biz'])

export const flightSchema = z
  .object({
    departureCode: z.string().trim().min(1, 'Departure airport required'),
    departureTimeLocal: z.string().min(1, 'Departure local time required'),
    arrivalCode: z.string().trim().min(1, 'Arrival airport required'),
    arrivalTimeLocal: z.string().min(1, 'Arrival local time required'),
    flightNumber: z
      .string()
      .trim()
      .min(3, 'Flight number required')
      .transform((val) => val.toUpperCase()),
    airlineCode: z.string().trim().min(1, 'Airline required'),
    ticketClass: ticketClassSchema,
    seatNo: z
      .string()
      .nullable()
      .transform((val) => val || null),
    seatPos: z.string().nullable(),
    aircraftCode: z
      .string()
      .trim()
      .nullable()
      .transform((val) => val || null),
    tailNo: z
      .string()
      .trim()
      .nullable()
      .transform((val) => val || null),
  })
  .refine((data) => data.departureCode !== data.arrivalCode, {
    message: 'Departure and arrival airports must differ',
    path: ['arrivalCode'],
  })

export type FlightFormValues = z.infer<typeof flightSchema>
