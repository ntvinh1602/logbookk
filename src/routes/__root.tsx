import {
  HeadContent,
  Scripts,
  Outlet,
  createRootRouteWithContext,
  useRouteContext,
} from '@tanstack/react-router'
import { QueryClientProvider } from '@tanstack/react-query'

import appCss from '../styles.css?url'

import type { QueryClient } from '@tanstack/react-query'
import NotFound from '@/components/not-found'
import { ThemeProvider } from '@/components/theme-provider'
import { Toaster } from '@/components/ui/sonner'

interface MyRouterContext {
  queryClient: QueryClient
}

export const Route = createRootRouteWithContext<MyRouterContext>()({
  head: () => ({
    meta: [
      {
        charSet: 'utf-8',
      },
      {
        name: 'viewport',
        content: 'width=device-width, initial-scale=1',
      },
      {
        title: 'Logbook',
      },
    ],
    links: [
      {
        rel: 'stylesheet',
        href: appCss,
      },
    ],
  }),
  component: RootComponent,
  shellComponent: RootDocument,
  notFoundComponent: NotFound,
})

function RootComponent() {
  const { queryClient } = useRouteContext({ from: '__root__' })

  return (
    <ThemeProvider>
      <QueryClientProvider client={queryClient}>
        <Outlet />
      </QueryClientProvider>
    </ThemeProvider>
  )
}

function RootDocument({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <HeadContent />
        <script
          dangerouslySetInnerHTML={{
            __html: `(function(){try{var t=localStorage.getItem('theme');if(t==='dark'||(!t&&matchMedia('(prefers-color-scheme:dark)').matches))document.documentElement.classList.add('dark')}catch(e){}})()`,
          }}
        />
      </head>
      <body>
        {children}
        <Scripts />
        <Toaster/>
      </body>
    </html>
  )
}
