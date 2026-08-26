import { useEffect, useRef } from 'react'

interface TradingViewMiniChartProps {
  symbol: string
  timeFrame?: string
  theme?: 'light' | 'dark'
  transparent?: boolean
  className?: string
}

let scriptPromise: Promise<void> | null = null

function loadTradingView() {
  if (typeof window === 'undefined') {
    return Promise.resolve()
  }

  if (customElements.get('tv-mini-chart')) {
    return Promise.resolve()
  }

  if (scriptPromise) {
    return scriptPromise
  }

  scriptPromise = new Promise<void>((resolve, reject) => {
    const src = 'https://widgets.tradingview-widget.com/w/en/tv-mini-chart.js'

    const existing = document.querySelector<HTMLScriptElement>(
      `script[src="${src}"]`,
    )

    if (existing) {
      existing.addEventListener('load', () => resolve(), { once: true })
      existing.addEventListener('error', reject, { once: true })
      return
    }

    const script = document.createElement('script')

    script.type = 'module'
    script.src = src

    script.onload = () => resolve()
    script.onerror = () =>
      reject(new Error('Failed to load TradingView Mini Chart'))

    document.head.appendChild(script)
  })

  return scriptPromise
}

export function TradingViewMiniChart({
  symbol,
  timeFrame = '7D',
  theme,
  transparent = true,
  className = 'w-full',
}: TradingViewMiniChartProps) {
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    loadTradingView().catch(console.error)
  }, [])

  useEffect(() => {
    if (!containerRef.current) return

    const container = containerRef.current

    container.innerHTML = ''

    const chart = document.createElement('tv-mini-chart')

    chart.setAttribute('symbol', symbol)
    chart.setAttribute('time-frame', timeFrame)

    if (theme) {
      chart.setAttribute('theme', theme)
    }

    if (transparent) {
      chart.setAttribute('transparent', '')
    }

    container.appendChild(chart)

    return () => {
      container.innerHTML = ''
    }
  }, [symbol, timeFrame, theme, transparent])

  return <div ref={containerRef} className={className} />
}
