"use client"

import { TxnItem } from "@/features/fund/ui/tx-item"
import { ItemGroup, ItemTitle } from "@/components/ui/item"
import StatusLabel from "@/components/status-label"
import { useTransactionsData } from "./transactions-data-context"
import type { EventStock } from "@/features/fund/fund.types"

function mapStockTxToTxItem(tx: EventStock) {
  return {
    id: String(tx.tx_id),
    created_at: tx.created_at,
    operation: tx.operation,
    memo: tx.ticker,
    value: tx.net_proceed,
    category: "stock" as const,
  }
}

export function TransactionsListSection() {
  const {
    state: { data, isLoading, error },
  } = useTransactionsData()

  if (isLoading) return <StatusLabel type="loading" />
  if (error) return <StatusLabel type="error" />

  return (
    <div className="flex flex-col">
      {data.length > 0 && (
        <ItemGroup className="gap-2">
          <ItemTitle className="pb-2">Found {data.length} transactions</ItemTitle>
          {data.map((tx) => (
            <TxnItem key={tx.tx_id} tx={mapStockTxToTxItem(tx)} />
          ))}
        </ItemGroup>
      )}
    </div>
  )
}
