# HomeSphere API Architecture (REST)

## 1) Service Decomposition

- **API Gateway**: auth validation, rate limiting, request tracing.
- **Identity Service**: OTP auth, JWT issuance, RBAC.
- **User Service**: profile, addresses, KYC, role onboarding.
- **Booking Service**: service catalog, booking lifecycle, tracking.
- **Interior Service**: projects, moodboards, BOQ, milestones.
- **Commission & Referral Service**: commission rule engine, settlements, MLM-style referral payouts.
- **Wallet & Payments Service**: wallet ledger, Razorpay/Cashfree/COD orchestration.
- **Subscription Service**: AMC and recurring plan management.
- **Notification Service**: push, WhatsApp, SMS, email, in-app.
- **Analytics & Reports Service**: BI aggregates, city/franchise/revenue dashboards.
- **Support/CRM Service**: tickets, SLA, assignment workflows.

## 2) API Standards

- REST + JSON (`/api/v1/*`), OpenAPI-first.
- JWT access token + refresh token rotation.
- Idempotency keys for payment & booking create endpoints.
- Cursor pagination (`next_cursor`, `limit`).
- Standard envelope:

```json
{
  "success": true,
  "data": {},
  "meta": {},
  "error": null
}
```

## 3) Key Endpoint Map

### Auth
- `POST /auth/otp/request`
- `POST /auth/otp/verify`
- `POST /auth/refresh`

### Customer
- `GET /customer/profile`
- `POST /customer/addresses`
- `POST /customer/bookings`
- `GET /customer/bookings/{id}/track`
- `POST /customer/referrals/invite`
- `GET /customer/wallet`

### Vendor/Technician
- `POST /vendor/kyc`
- `PATCH /vendor/availability`
- `POST /vendor/jobs/{id}/accept`
- `POST /vendor/jobs/{id}/reject`
- `POST /vendor/jobs/{id}/proofs`
- `GET /vendor/earnings`
- `POST /vendor/withdrawals`

### Interior Designer
- `POST /designer/projects`
- `POST /designer/projects/{id}/assets`
- `POST /designer/projects/{id}/boq`
- `POST /designer/projects/{id}/milestones`
- `POST /designer/projects/{id}/approvals/request`

### Admin/Franchise/Accountant
- `GET /admin/dashboard`
- `POST /admin/vendors/{id}/approve`
- `POST /admin/commission-rules`
- `POST /admin/subscription-plans`
- `GET /admin/reports/revenue`
- `GET /admin/reports/referrals`
- `GET /admin/reports/gst`

## 4) Event-driven Integrations

Publish domain events to Kafka/SNS/SQS:
- `booking.created`, `booking.assigned`, `booking.completed`
- `payment.success`, `payment.failed`, `refund.completed`
- `referral.reward.credited`
- `commission.settled`
- `subscription.expiring`

## 5) Security Controls

- RBAC policy enforcement middleware.
- Rate limits by IP + user + endpoint group.
- PII encryption at rest (KMS-backed keys).
- Signed URLs for uploaded files (proofs/design assets).
- Audit trail for all admin and financial actions.

## 6) Suggested Stack

- Backend framework: NestJS / FastAPI / Spring Boot (modular monolith -> microservices).
- DB: PostgreSQL + Redis + object storage.
- Queue/stream: Kafka or AWS SQS/SNS.
- Search/logs: OpenSearch.
