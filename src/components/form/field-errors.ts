import type { ValidationError } from "@tanstack/react-form"

/**
 * Normalizes TanStack Form validation errors (which can be raw strings from
 * function validators or standard-schema issues) into the shape expected by
 * `FieldError`.
 */
export function toFieldErrorMessages(errors: ValidationError[]) {
  return errors
    .map((error) => ({
      message:
        typeof error === "string"
          ? error
          : (error as { message?: string } | undefined)?.message,
    }))
    .filter((error): error is { message: string } => Boolean(error.message))
}
