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

import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import logo from '@/assets/logo.webp'
import { LogOut } from 'lucide-react'

export function NavBar() {
  const navigate = useNavigate()
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
                render={<Link to="/" />}
                className={navigationMenuTriggerStyle()}
              >
                Home
              </NavigationMenuLink>
            </NavigationMenuItem>

            <NavigationMenuItem>
              <NavigationMenuTrigger>Investment</NavigationMenuTrigger>
              <NavigationMenuContent>
                <ul className="grid w-[200px]">
                  <li>
                    <NavigationMenuLink
                      render={
                        <Link
                          to="/fund/balance-sheet"
                          className="flex-row items-center gap-2"
                        >
                          Balance Sheet
                        </Link>
                      }
                    />
                    <NavigationMenuLink
                      render={
                        <Link
                          to="/fund/performance"
                          className="flex-row items-center gap-2"
                        >
                          Performance
                        </Link>
                      }
                    />
                    <NavigationMenuLink
                      render={
                        <Link
                          to="/fund/events"
                          className="flex-row items-center gap-2"
                        >
                          Events
                        </Link>
                      }
                    />
                  </li>
                </ul>
              </NavigationMenuContent>
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

        <Button variant="ghost" onClick={handleLogout} className="ml-auto">
          <LogOut />
          Log out
        </Button>
      </div>
    </header>
  )
}
