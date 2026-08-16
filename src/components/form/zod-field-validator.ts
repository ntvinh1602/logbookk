import type { ZodType } from "zod"

/**
 * Field validator wrapper for zod schemas that TanStack Form's standard
 * schema auto-detection rejects at the type level — schemas whose input
 * type is `unknown`, like `z.coerce.number()`, don't match the
 * `StandardSchemaV1<TData, ...>` branch of `FieldValidateOrFn`.
 */
export function zodFieldValidator(schema: ZodType) {
  return ({ value }: { value: unknown }) => {
    const result = schema.safeParse(value)
    return result.success
      ? undefined
      : result.error.issues.map((issue) => issue.message).join(", ")
  }
}
