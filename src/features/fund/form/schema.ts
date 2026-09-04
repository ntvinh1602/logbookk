import * as z from 'zod'

const positiveInt = (field: string) =>
  z
    .number()
    .int(`${field} must be a whole number`)
    .positive(`${field} must be positive`)

const nonNegativeInt = (field: string) =>
  z
    .number()
    .int(`${field} must be a whole number`)
    .min(0, `${field} cannot be negative`)

export const stockSchema = z.object({
  side: z.enum(['buy', 'sell']),
  stock_id: positiveInt('Stock ID'),
  price: nonNegativeInt('Price'),
  quantity: positiveInt('Quantity'),
  fee: nonNegativeInt('Fee'),
  tax: nonNegativeInt('Tax'),
  created_at: z.string(),
})

export const cashflowSchema = z.object({
  operation: z.enum(['deposit', 'withdraw', 'income', 'expense']),
  asset: positiveInt('Asset ID'),
  quantity: z.number().positive('Quantity must be positive'),
  fx_rate: z.number().min(1, 'FX Rate cannot be less than 1'),
  memo: z.string(),
  created_at: z.string(),
})

export const borrowSchema = z.object({
  principal: positiveInt('Principal'),
  lender: z.string(),
  rate: z.number().min(0, 'Interest rate cannot be negative'),
  created_at: z.string(),
})

export const repaySchema = z.object({
  repay_tx: positiveInt('Repay transaction ID'),
  interest: nonNegativeInt('Interest'),
  created_at: z.string(),
})
