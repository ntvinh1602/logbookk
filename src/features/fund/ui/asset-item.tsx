import {
  Item,
  ItemMedia,
  ItemContent,
  ItemTitle,
  ItemDescription,
} from '@/components/ui/item'
import { formatNum } from '@/lib/utils'

interface AssetItemProps {
  ticker: string
  name: string
  logo_url: string | null
  total_value: number
}

export function AssetItemTopStock({
  ticker,
  name,
  logo_url,
  total_value,
}: AssetItemProps) {
  return (
    <Item variant="muted">
      <ItemMedia variant="image">
        {logo_url && (
          <img
            src={`${import.meta.env.VITE_PUBLIC_SUPABASE_URL}/storage/v1/object/public/logo/stock/${logo_url}`}
            alt={name}
            width={44}
            height={44}
            loading="eager"
          />
        )}
      </ItemMedia>
      <ItemContent>
        <ItemTitle>{name}</ItemTitle>
        <ItemDescription>{ticker}</ItemDescription>
      </ItemContent>
      <ItemContent className="items-end">
        <ItemTitle>{formatNum(total_value)}</ItemTitle>
      </ItemContent>
    </Item>
  )
}
