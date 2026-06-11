# Backend Security Checklist

These controls must be verified on the Tongoy API before a production release.
The mobile app treats identifiers from the API as display/filter inputs only; the
backend must be the source of truth for authorization.

## Authorization and IDOR

- Every authenticated endpoint must derive the active user from the server-side
  session cookie, not from client-provided query parameters.
- Endpoints that receive course, semester, attendance, notes, or user IDs must
  verify that the session is allowed to read or mutate that resource.
- Requests such as `cp.php?u=<another-user>` must not disclose courses, notes,
  attendance, or profile data for another account.
- Professor/assistant roles must be checked server-side for course management or
  attendance actions.
- Authorization failures should return `401` or `403` with a generic message.

## QR Attendance

- QR URLs must contain a server-generated nonce/token with a short expiration.
- Tokens must be single-use or protected against replay during the attendance
  window.
- The backend must verify that the authenticated user belongs to the course and
  section encoded by the QR.
- The backend must reject QR URLs outside the active class window.
- Successful and rejected attendance attempts should be auditable without
  logging passwords, session cookie values, or full tokens.

## Session and Cookies

- Session cookies must be `HttpOnly`, `Secure`, and scoped to the expected path
  and domain.
- Session expiration must be enforced server-side even if the app restores an
  older cookie locally.
- Logout should invalidate the server-side session, not only the local cookie.

## API Robustness

- API responses should use stable JSON schemas and appropriate HTTP status
  codes.
- Error responses must avoid returning HTML pages to JSON clients.
- Sensitive fields, raw SQL errors, stack traces, and implementation details
  must not be exposed to the mobile app.
