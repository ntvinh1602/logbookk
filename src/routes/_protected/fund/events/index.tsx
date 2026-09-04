import { createFileRoute, redirect } from '@tanstack/react-router'

export const Route = createFileRoute('/_protected/fund/events/')({
  beforeLoad: () => {
    throw redirect({
      to: '/fund/events/$event',
      params: { event: 'stock' },
      replace: true,
    })
  },
})
