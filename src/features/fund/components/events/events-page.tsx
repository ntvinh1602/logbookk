import type { ComponentType } from 'react'
import { getRouteApi, notFound } from '@tanstack/react-router'
import { FilterToggleGroup } from '@/components/filter/toggle-options'
import { FieldGroup } from '@/components/ui/field'
import { StockForm } from '@/features/fund/form/stockForm'
import { CashflowForm } from '@/features/fund/form/cashflowForm'
import { BorrowForm } from '@/features/fund/form/borrowForm'
import { RepayForm } from '@/features/fund/form/repayForm'
import { EVENT_CATEGORY } from '@/features/fund/config'
import type { Events } from '@/features/fund/config'
import { EventsFilter } from './events-filter'
import { EventBody } from './event-body'

const routeApi = getRouteApi('/_protected/fund/events/$event')

const EVENT_FORMS = {
  stock: StockForm,
  cashflow: CashflowForm,
  borrow: BorrowForm,
  repay: RepayForm,
} satisfies Record<Events, ComponentType>

function AddEventForm({ event }: { event: Events }) {
  const Form = EVENT_FORMS[event]
  return <Form />
}

function isEventKey(value: unknown): value is Events {
  return typeof value === 'string' && Object.hasOwn(EVENT_CATEGORY, value)
}

/* ---------- page shell ---------- */

export function EventsPage() {
  const { event } = routeApi.useParams()
  const navigate = routeApi.useNavigate()

  if (!isEventKey(event)) throw notFound()

  return (
    <div className="flex flex-col max-w-screen-lg mx-auto py-15 gap-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Transaction Events</h1>
        <AddEventForm event={event} />
      </div>

      <FieldGroup className="gap-4">
        <div className="flex w-full flex-col gap-4 md:flex-row md:items-center">
          <div className="w-full min-w-0 overflow-hidden border-b border-muted md:flex-1">
            <FilterToggleGroup
              value={event}
              onValueChange={(v) => {
                // Switching category resets the filters to their defaults.
                if (v && v !== event && isEventKey(v)) {
                  navigate({
                    to: '/fund/events/$event',
                    params: { event: v },
                    search: {
                      period: 'M3',
                      from: undefined,
                      to: undefined,
                      op: undefined,
                    },
                  })
                }
              }}
              options={EVENT_CATEGORY}
            />
          </div>
        </div>

        {EVENT_CATEGORY[event].dateful && <EventsFilter event={event} />}
      </FieldGroup>

      <EventBody event={event} />
    </div>
  )
}
