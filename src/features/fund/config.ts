import {
  Banknote,
  Box,
  Coins,
  HandCoins,
  Handshake,
  PiggyBank,
  ShoppingBag,
  TrendingDown,
  TrendingUp,
  Upload,
} from 'lucide-react'

export const FUND_START_YEAR = 2021

export const VNINDEX_TICKER = 'VNINDEX'

export const EVENT_DATE_KEY = 'yyyy-MM-dd'

export const EVENT_CATEGORY = {
  stock: {
    label: 'Stock',
    icon: Box,
    operations: {
      buy: {
        label: 'Buy',
        icon: ShoppingBag,
        color: 'bg-positive/10 text-positive',
      },
      sell: {
        label: 'Sell',
        icon: Coins,
        color: 'bg-negative/10 text-negative',
      },
    },
    dateful: true,
  },
  cashflow: {
    label: 'Cashflow',
    icon: Banknote,
    operations: {
      deposit: {
        label: 'Deposit',
        icon: PiggyBank,
        color: 'bg-positive/10 text-positive',
        memo: ['Cash deposit', 'EPF monthly contribution', 'Reconciliation'],
      },
      withdraw: {
        label: 'Withdraw',
        icon: Upload,
        color: 'bg-negative/10 text-negative',
        memo: ['Reconciliation', 'Cash withdrawal'],
      },
      income: {
        label: 'Income',
        icon: TrendingUp,
        color: 'bg-positive/10 text-positive',
        memo: [
          'CASA balance interest',
          'EPF dividend',
          'Cash dividend from stock',
          'Other reward/income',
          'Loyalty program rewards',
        ],
      },
      expense: {
        label: 'Expense',
        icon: TrendingDown,
        color: 'bg-negative/10 text-negative',
        memo: ['Margin interest', 'Cash advance interest', 'Operational fees'],
      },
    },
    dateful: true,
  },
  borrow: {
    label: 'Borrow',
    icon: HandCoins,
    operations: {},
    dateful: false,
  },
  repay: {
    label: 'Repay',
    icon: Handshake,
    operations: {},
    dateful: false,
  },
} as const

export const TIME_PRESET = {
  M1: { label: 'Last 1 months', range: 1 },
  M3: { label: 'Last 3 months', range: 3 },
  M6: { label: 'Last 6 months', range: 6 },
  M12: { label: 'Last 1 year', range: 12 },
  custom: { label: 'Custom', range: 0 },
}

// Derived type
export type Events = keyof typeof EVENT_CATEGORY
export type TimePresets = keyof typeof TIME_PRESET
export type CashflowOps = keyof typeof EVENT_CATEGORY.cashflow.operations
export type StockOps = keyof typeof EVENT_CATEGORY.stock.operations
