import { type BenchmarkChartCols, type EquityChartCols } from './types'

export function BenchmarkChartConvert({ d, p, v }: BenchmarkChartCols) {
  const out = new Array(d.length)
  for (let i = 0; i < d.length; i++) {
    out[i] = {
      t: d[i] * 86_400_000,
      portfolio_value: p[i],
      vni_value: v[i],
    }
  }
  return out
}

export function EquityChartConvert({ d, e, c }: EquityChartCols) {
  const out = new Array(d.length)
  for (let i = 0; i < d.length; i++) {
    out[i] = {
      t: d[i] * 86_400_000,
      net_equity: e[i],
      cumulative_cashflow: c[i],
    }
  }
  return out
}
