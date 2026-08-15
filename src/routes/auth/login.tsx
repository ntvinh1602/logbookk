import { createFileRoute } from '@tanstack/react-router'

import { LoginForm } from '@/features/auth/login-form'

export const Route = createFileRoute('/auth/login')({
  component: Login,
})

function Login() {
  return (
    <div className="flex min-h-svh w-full items-center justify-center">
      <div className="w-full max-w-sm">
        <LoginForm />
      </div>
    </div>
  )
}
