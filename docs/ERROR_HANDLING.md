# Error Handling

Version: 1.1\
Last Reviewed: 2026-09-16\
Status: Active

- Preserve actionable operation context.
- User-facing errors explain recovery when recovery is possible.
- Never log secrets or raw sensitive capture content by default.
- Do not swallow correctness-changing failures.
- Retry behavior is intentional and bounded.
- Non-idempotent external operations are not automatically retried without a
  safe reconciliation/idempotency mechanism.
- Cleanup/finalization failures are surfaced when they can change correctness.

## Flick categories

At minimum, later implementation should distinguish:

- durable capture-write failure;
- ingestion/transcription/OCR failure;
- semantic backend unavailable/failure;
- routing unresolved;
- local output persistence failure;
- external export ambiguous/failure;
- permission denied/restricted.

`Unsorted` is semantic-routing state, not a generic error bucket.
