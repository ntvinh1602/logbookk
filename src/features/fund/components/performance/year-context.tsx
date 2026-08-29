

import { createContext, use } from "react"
import { useNavigate } from "@tanstack/react-router"

interface PerformanceYearContextValue {
  year: number
  setYear: (year: number) => void
  startYear: number
}

const PerformanceYearContext = createContext<PerformanceYearContextValue | null>(
  null,
)

export function PerformanceYearProvider({
  startYear,
  initialYear,
  children,
}: {
  startYear: number
  initialYear: number
  children: React.ReactNode
}) {
  const navigate = useNavigate()

  const setYear = (year: number) => {
    navigate({ to: '/fund/performance/$year', params: { year: year.toString() } })
  }

  return (
    <PerformanceYearContext.Provider value={{ year: initialYear, setYear, startYear }}>
      {children}
    </PerformanceYearContext.Provider>
  )
}

export function usePerformanceYear() {
  const ctx = use(PerformanceYearContext)
  if (!ctx) throw new Error("usePerformanceYear must be used within PerformanceYearProvider")
  return ctx
}
