import { useState } from 'react'
import { SearchIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Field, FieldLabel } from '@/components/ui/field'
import { ButtonGroup } from '@/components/ui/button-group'
import {
  InputGroup,
  InputGroupInput,
} from '@/components/ui/input-group'

interface FilterSearchProps {
  placeholder: string
  value: string
  onCommit: (value: string) => void
}

export function FilterSearch({
  placeholder,
  value,
  onCommit,
}: FilterSearchProps) {
  const [searchInput, setSearchInput] = useState(value)
  // The input is a draft until it is committed, so it has to follow the value
  // when the committed one changes from the outside — a filter reset, or the
  // browser's back/forward buttons. Without this the stale text lingers.
  const [committed, setCommitted] = useState(value)

  if (value !== committed) {
    setCommitted(value)
    setSearchInput(value)
  }

  const commitSearch = () => {
    onCommit(searchInput)
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') commitSearch()
  }

  return (
    <Field orientation="horizontal">
      <FieldLabel className="sr-only">{placeholder}</FieldLabel>
      <ButtonGroup className="w-full">
        <InputGroup>
          <InputGroupInput
            placeholder={placeholder}
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            onKeyDown={handleKeyDown}
            className="w-full"
          />
        </InputGroup>
        <Button variant="outline" onClick={commitSearch} aria-label="Search" className="border-input text-input">
          <SearchIcon />
        </Button>
      </ButtonGroup>
    </Field>
  )
}
