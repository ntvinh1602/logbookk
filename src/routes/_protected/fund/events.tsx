import { AddEventProvider } from '@/features/fund/components/events/add-event-context'
import { createFileRoute, Outlet, redirect } from '@tanstack/react-router'

export const Route = createFileRoute('/_protected/fund/events')({
  component: RouteComponent,
  beforeLoad: ({ location }) => {
    if (location.pathname === '/fund/events') {
      throw redirect({ to: '/fund/events/stock' })
    }
  },
})

function RouteComponent() {
  return (
    <AddEventProvider>
      <Outlet />
    </AddEventProvider>
  )
}
