import { createFileRoute, redirect, Outlet } from '@tanstack/react-router'
import { NavBar } from '@/components/nav-bar'
import { getCurrentUser } from '@/lib/auth/get-current-user'

export const Route = createFileRoute('/_protected')({
  beforeLoad: async () => {
    const user = await getCurrentUser()

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
