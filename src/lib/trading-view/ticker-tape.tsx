import { useEffect, useRef } from 'react'

interface TradingViewTickerTapeProps {
  symbols: string[]
  direction?: 'horizontal' | 'vertical'
  itemSize?: 'compact' | 'normal'
  hoverType?: 'performance-grid' | 'default'
  colorTheme?: 'light' | 'dark'
  isTransparent?: boolean
  showHover?: boolean
  hideChart?: boolean
  width?: string
  height?: string
  className?: string
}

let scriptPromise: Promise<void> | null = null

function loadTradingView() {
  if (typeof window === 'undefined') {
    return Promise.resolve()
  }

  if (customElements.get('tv-ticker-tape')) {
    return Promise.resolve()
  }

  if (scriptPromise) {
    return scriptPromise
  }

  scriptPromise = new Promise<void>((resolve, reject) => {
    const src = 'https://widgets.tradingview-widget.com/w/en/tv-ticker-tape.js'

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
      reject(new Error('Failed to load TradingView Ticker Tape'))

    document.head.appendChild(script)
  })

  return scriptPromise
}

export function TradingViewTickerTape({
  symbols,
  direction = 'horizontal',
  itemSize = 'normal',
  hoverType = 'performance-grid',
  colorTheme,
  isTransparent = true,
  showHover = true,
  hideChart = true,
  width = '100%',
  height = '46',
  className = 'w-full',
}: TradingViewTickerTapeProps) {
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    loadTradingView().catch(console.error)
  }, [])

  useEffect(() => {
    if (!containerRef.current) return

    const container = containerRef.current

    container.innerHTML = ''

    const ticker = document.createElement('tv-ticker-tape')

    ticker.setAttribute('symbols', symbols.join(','))
    ticker.setAttribute('direction', direction)
    ticker.setAttribute('item-size', itemSize)
    ticker.setAttribute('hover-type', hoverType)
    ticker.setAttribute('width', width)
    ticker.setAttribute('height', height)

    if (colorTheme) {
      ticker.setAttribute('theme', colorTheme)
    }

    if (isTransparent) {
      ticker.setAttribute('transparent', '')
    }

    if (showHover) {
      ticker.setAttribute('show-hover', '')
    }

    if (hideChart) {
      ticker.setAttribute('hide-chart', '')
    }

    container.appendChild(ticker)

    return () => {
      container.innerHTML = ''
    }
  }, [symbols, direction, itemSize, hoverType, colorTheme, isTransparent, showHover, hideChart, width, height])

  return <div ref={containerRef} className={className} />
}
