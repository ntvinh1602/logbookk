import { Skeleton } from "@/components/ui/skeleton"

export function AssetItemSkeleton() {
  return (
    <div className="flex items-center gap-3 rounded-xl bg-muted/50 p-3">
      <Skeleton className="size-11 shrink-0" />

      <div className="flex min-w-0 flex-1 flex-col gap-2">
        <Skeleton className="h-4 w-32" />
        <Skeleton className="h-3 w-28" />
      </div>

      <div className="flex shrink-0 flex-col items-end gap-2">
        <Skeleton className="h-4 w-20" />
        <Skeleton className="h-3 w-16" />
      </div>
    </div>
  )
}