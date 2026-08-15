import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/_protected/flight/history')({
  component: RouteComponent,
})

function RouteComponent() {
  return <div>Hello "/flight/history"!</div>
}
