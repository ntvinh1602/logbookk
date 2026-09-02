import { useState, useRef } from 'react'
import { Button } from '@/components/ui/button'
import { Field } from '@/components/ui/field'
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from '../ui/sheet'

const FORM_ID = 'dialog-form'

type FormComponentProps = {
  onSuccess?: () => void
  formId: string
  onLoadingChange: (loading: boolean) => void
  resetFormRef: { current: () => void }
}

type FormDialogWrapperProps = {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  subtitle?: string
  FormComponent: React.ComponentType<FormComponentProps>
  onSuccess?: () => void
}

export function FormDialogWrapper({
  open,
  onOpenChange,
  title,
  subtitle,
  FormComponent,
  onSuccess,
}: FormDialogWrapperProps) {
  const [loading, setLoading] = useState(false)
  const resetFormRef = useRef<() => void>(() => {})

  const handleSuccess = () => {
    onSuccess?.()
    onOpenChange(false)
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent>
        <SheetHeader>
          <SheetTitle>{title}</SheetTitle>
          {subtitle && <SheetDescription>{subtitle}</SheetDescription>}
        </SheetHeader>
        <FormComponent
          onSuccess={handleSuccess}
          formId={FORM_ID}
          onLoadingChange={setLoading}
          resetFormRef={resetFormRef}
        />
        <SheetFooter>
          <Field>
            <Button
              type="button"
              variant="outline"
              onClick={() => resetFormRef.current()}
            >
              Reset
            </Button>
            <Button type="submit" form={FORM_ID} disabled={loading}>
              {loading ? 'Submitting...' : 'Submit'}
            </Button>
          </Field>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  )
}
