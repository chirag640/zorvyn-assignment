# API Contract Standard

## Success Envelope

- success: true
- message: string
- data: object or array
- meta: optional object

## Error Envelope

- success: false
- error.code: string
- error.message: string
- error.details: optional object

## Rules

- Do not break envelope shape without migration plan.
- Keep code values stable for client branching.
- Use typed models and parsing tests.

