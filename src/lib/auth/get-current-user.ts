import { createServerFn } from '@tanstack/react-start'
import { createClient } from '@/lib/supabase/server'

export const getCurrentUser = createServerFn({
  method: 'GET',
}).handler(async () => {
  const supabase = createClient()

  const { data, error } = await supabase.auth.getUser()

  if (error) return null

  return data.user
})
