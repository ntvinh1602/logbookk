import {
  NavigationMenu,
  NavigationMenuContent,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
  NavigationMenuTrigger,
  navigationMenuTriggerStyle,
} from '@/components/ui/navigation-menu'
import { Link, useNavigate } from '@tanstack/react-router'
import { Moon, Sun } from 'lucide-react'

import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import logo from '@/assets/logo.webp'
import { useTheme } from '@/components/theme-provider'

export function NavBar() {
  const navigate = useNavigate()
  const { theme, toggleTheme } = useTheme()
  const handleLogout = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    navigate({ to: '/auth/login' })
  }
  return (
    <header className="sticky top-0 z-50 flex h-14 backdrop-blur-xl bg-transparent">
      <div className="flex w-full max-w-screen-2xl mx-auto items-center backdrop-blur-xl bg-transparent gap-4">
        <img src={logo} alt="Logo" className="h-10 w-auto" />
        <NavigationMenu>
          <NavigationMenuList>
            <NavigationMenuItem>
              <NavigationMenuLink
                render={<Link to="/fund/dashboard" />}
                className={navigationMenuTriggerStyle()}
              >
                Dashboard
              </NavigationMenuLink>
            </NavigationMenuItem>
            <NavigationMenuItem>
              <NavigationMenuLink
                render={<Link to="/fund/performance/$year" params={{ year: new Date().getFullYear().toString() }} />}
                className={navigationMenuTriggerStyle()}
              >
                Performance
              </NavigationMenuLink>
            </NavigationMenuItem>
            <NavigationMenuItem>
              <NavigationMenuLink
                render={<Link to="/fund/events" />}
                className={navigationMenuTriggerStyle()}
              >
                Events
              </NavigationMenuLink>
            </NavigationMenuItem>

            <NavigationMenuItem>
              <NavigationMenuTrigger>Flight</NavigationMenuTrigger>
              <NavigationMenuContent>
                <ul className="grid w-[200px]">
                  <li>
                    <NavigationMenuLink
                      render={
                        <Link
                          to="/flight/map"
                          className="flex-row items-center gap-2"
                        >
                          Map
                        </Link>
                      }
                    />
                    <NavigationMenuLink
                      render={
                        <Link
                          to="/flight/history"
                          className="flex-row items-center gap-2"
                        >
                          History
                        </Link>
                      }
                    />
                  </li>
                </ul>
              </NavigationMenuContent>
            </NavigationMenuItem>
          </NavigationMenuList>
        </NavigationMenu>

        <div className="ml-auto flex items-center gap-2">
          <Button variant="ghost" size="icon" onClick={toggleTheme}>
            {theme === 'dark' ? <Sun className="size-4" /> : <Moon className="size-4" />}
          </Button>
          <Button variant="ghost" onClick={handleLogout}>
            Log out
          </Button>
        </div>
      </div>
    </header>
  )
}
