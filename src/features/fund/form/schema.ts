import * as z from 'zod'

export const stockSchema = z.object({
  side: z.enum(['buy', 'sell']),

  stock_id: z
    .number()
    .int('Stock ID must be a whole number')
    .positive('Stock ID is required'),

  price: z
    .number()
    .int('Price must be a whole number')
    .min(0, 'Price cannot be negative'),

  quantity: z
    .number()
    .int('Quantity must be a whole number')
    .positive('Quantity must be positive'),

  fee: z
    .number()
    .int('Fee must be a whole number')
    .min(0, 'Fee cannot be negative'),

  tax: z
    .number()
    .int('Tax must be a whole number')
    .min(0, 'Tax cannot be negative'),

  created_at: z.string(),
})

export const cashflowSchema = z.object({
  operation: z.enum(['deposit', 'withdraw', 'income', 'expense']),
  asset: z
    .number()
    .int('Asset ID transaction id must be a whole number')
    .positive('Asset ID must be positive'),
  quantity: z.number().positive('Quantity must be positive'),
  fx_rate: z.number().min(1, 'FX Rate cant be less than 1').optional(),
  memo: z.string(),
  created_at: z.string().optional(),
})

export const borrowSchema = z.object({
  principal: z
    .number()
    .int('Principal must be a whole number')
    .positive('Principal must be positive'),
  lender: z.string(),
  rate: z.number().min(0, 'Interest rate cannot be negative'),
  created_at: z.string().optional(),
})

export const repaySchema = z.object({
  repay_tx: z
    .number()
    .int('Repay transaction ID must be a whole number')
    .positive('Repay transaction ID must be positive'),
  interest: z
    .number()
    .int('Interest must be a whole number')
    .min(0, 'Interest cannot be negative'),
  created_at: z.string().optional(),
})
