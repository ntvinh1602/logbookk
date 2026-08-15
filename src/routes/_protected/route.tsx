import { createFileRoute, redirect, Outlet } from '@tanstack/react-router'

import { NavBar } from '@/components/nav-bar'
import { fetchUser } from '@/lib/supabase/fetch-user-server-fn'

export const Route = createFileRoute('/_protected')({
  beforeLoad: async () => {
    const user = await fetchUser()

    if (!user) {
      throw redirect({ to: '/auth/login' })
    }

    return {
      user,
    }
  },
  component: ProtectedLayout,
})

function ProtectedLayout() {
  return (
    <>
      <NavBar />
      <Outlet />
    </>
  )
}
