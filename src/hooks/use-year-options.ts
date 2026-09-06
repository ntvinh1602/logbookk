interface YearOptions {
  /** Years from the current year down to `startYear`, e.g. [2026, …, 2019]. */
  years: number[]
  /** Label map for those years, keyed by string. */
  yearOptions: Record<string, { label: string }>
}

/**
 * Options for a year `<FilterSelect>`, covering every year from the current
 * one back to a given start year. Returns the years themselves too so callers
 * can feed `optionsOrder={years.map(String)}` — integer-like keys sort
 * ascending in JS otherwise.
 */
export function useYearOptions(startYear: number): YearOptions {
  const years = Array.from(
    { length: new Date().getFullYear() - startYear + 1 },
    (_, i) => startYear + i,
  ).reverse()

  const yearOptions: Record<string, { label: string }> = Object.fromEntries(
    years.map((year) => [String(year), { label: String(year) }]),
  )

  return { years, yearOptions }
}
