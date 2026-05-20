# HomeSphere Testing Access

This repository currently contains product architecture and planning artifacts (no runnable deployed app yet).

## Current Testing URLs (Local)

- Mobile Customer App (Flutter): `http://localhost:3000` *(placeholder while mobile backend/web preview is scaffolded)*
- Vendor App (Flutter): `http://localhost:3001` *(placeholder while vendor backend/web preview is scaffolded)*
- Admin Web Panel (React): `http://localhost:5173`
- API Base URL: `http://localhost:8080/api/v1`

## Proposed Staging URLs (for UAT once deployed)

- Customer App Web Preview: `https://staging-app.homesphere.in`
- Vendor App Web Preview: `https://staging-vendor.homesphere.in`
- Admin Dashboard: `https://staging-admin.homesphere.in`
- API: `https://staging-api.homesphere.in/api/v1`

## Testing Credentials (UAT Seed Accounts)

> OTP-based login is primary. For non-OTP test mode, use password credentials below after seed scripts are introduced.

| Role | Login | Password | Notes |
|---|---|---|---|
| Super Admin | `superadmin@homesphere.test` | `HomeSphere@123` | Full platform controls |
| Admin | `admin@homesphere.test` | `HomeSphere@123` | Vendor/booking/commission operations |
| Franchise Manager | `franchise.blr@homesphere.test` | `HomeSphere@123` | City/franchise scope |
| Customer | `customer1@homesphere.test` | `HomeSphere@123` | Booking/referral/wallet flow |
| Vendor | `vendor1@homesphere.test` | `HomeSphere@123` | Job queue and earnings |
| Technician | `tech1@homesphere.test` | `HomeSphere@123` | Assigned jobs and proof upload |
| Interior Designer | `designer1@homesphere.test` | `HomeSphere@123` | Design asset and BOQ flow |
| Accountant | `accounts@homesphere.test` | `HomeSphere@123` | Settlement/GST reports |
| Support Agent | `support1@homesphere.test` | `HomeSphere@123` | CRM ticket resolution |

## Notes

- Since code scaffolding and deployment are pending, the above URLs/credentials are **test planning references**, not active endpoints yet.
- On implementation start, replace these with real staging links and secrets from vault-managed environment variables.
