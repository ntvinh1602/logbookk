import { withSupabase } from 'npm:@supabase/server'
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

const TELEGRAM_BOT_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN')
const TELEGRAM_CHAT_ID = Deno.env.get('TELEGRAM_CHAT_ID')
const OPENEXCHANGERATES_APP_ID = Deno.env.get('OPENEXCHANGERATES_APP_ID')

interface ExchangeRates {
  [key: string]: number
}

interface Currency {
  id: number
  iso_code: string
}

interface FxRateRow {
  currency_id: number
  date: string
  close: number
}

// Helper function to send a Telegram message
async function sendTelegramMessage(message: string) {
  if (!TELEGRAM_BOT_TOKEN || !TELEGRAM_CHAT_ID) {
    return
  }

  await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      chat_id: TELEGRAM_CHAT_ID,
      text: message,
    }),
  })
}

async function getExchangeRates(): Promise<ExchangeRates | null> {
  if (!OPENEXCHANGERATES_APP_ID) {
    console.error('OPENEXCHANGERATES_APP_ID is not configured')
    return null
  }

  const url = `https://openexchangerates.org/api/latest.json?app_id=${OPENEXCHANGERATES_APP_ID}`

  try {
    const response = await fetch(url)

    if (!response.ok) {
      console.error(
        `OpenExchangeRates API request failed with status: ${response.status}`,
      )
      return null
    }

    const data: { rates: ExchangeRates } = await response.json()

    return data.rates
  } catch (error) {
    console.error('Error fetching from OpenExchangeRates API:', error)

    return null
  }
}

async function getCurrencies(supabase: SupabaseClient): Promise<Currency[]> {
  const { data, error } = await supabase
    .schema('dim')
    .from('currency')
    .select('id, iso_code')
    .neq('iso_code', 'VND')

  if (error) {
    console.error('Error fetching currencies:', error)
    return []
  }

  return data ?? []
}

const handler = withSupabase({ auth: 'secret' }, async (_req, ctx) => {
  try {
    const supabase = ctx.supabaseAdmin

    const [rates, currencies] = await Promise.all([
      getExchangeRates(),
      getCurrencies(supabase),
    ])

    if (!rates?.VND) {
      throw new Error('Failed to fetch exchange rates or missing VND rate.')
    }

    if (currencies.length === 0) {
      throw new Error('No currencies found to process.')
    }

    const vndRate = rates.VND
    const today = new Date().toISOString().split('T')[0]

    const dataToUpsert: FxRateRow[] = currencies
      .map((currency) => {
        const currencyRate = rates[currency.iso_code]

        if (!currencyRate) {
          console.warn(
            `Rate for ${currency.iso_code} not found in API response. Skipping.`,
          )

          return null
        }

        // OpenExchangeRates returns:
        // 1 USD = currencyRate * target currency
        //
        // Therefore:
        // 1 unit of target currency = VND / target currency rate
        const rateToVnd = vndRate / currencyRate

        return {
          currency_id: currency.id,
          date: today,
          close: rateToVnd,
        }
      })
      .filter((item): item is FxRateRow => item !== null)

    if (dataToUpsert.length === 0) {
      throw new Error('No valid exchange rates could be calculated.')
    }

    const { error: upsertError } = await supabase
      .schema('dwd')
      .from('daily_fxrate_close')
      .upsert(dataToUpsert, {
        onConflict: 'currency_id,date',
      })

    if (upsertError) {
      throw new Error(`Database error: ${upsertError.message}`)
    }

    return Response.json({
      success: true,
      message: 'Exchange rate fetching complete.',
      stats: {
        successful_updates: dataToUpsert.length,
        total_currencies: currencies.length,
      },
    })
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)

    console.error('Critical error:', errorMessage)

    await sendTelegramMessage(
      `🚨 ERROR (fetch-exchange-rates)\n\n${errorMessage}`,
    )

    return Response.json(
      {
        success: false,
        error: errorMessage,
      },
      {
        status: 500,
      },
    )
  }
})

const mod = {
  fetch: handler,
}

export default mod
