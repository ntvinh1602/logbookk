import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/_protected/fund/events')({
  component: RouteComponent,
})

function RouteComponent() {
  return <div>Hello "/fund/events"!</div>
}
