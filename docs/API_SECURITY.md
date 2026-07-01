# API Security — Smart Health Consulting

## Authentication

- **Laravel Sanctum** bearer tokens on all protected routes
- Tokens revoked on logout and password reset
- Login/register/forgot-password rate-limited to **10 requests/minute per IP**

## Role-based access control (RBAC)

| Role | Access |
|------|--------|
| **Patient** | Own profile, appointments, records, prescriptions, messages (with assigned doctors only) |
| **Doctor** | Own profile, availability, appointments, consultations, messages (with own patients only) |
| **Admin** | Platform stats, doctor verify/suspend, audit logs — **no** patient medical records or chat content |

## Authorization rules

### Appointments
- Patients book only **verified, non-suspended** doctors
- Patients/doctors can only view, reschedule, or cancel **their own** appointments
- Admins can manage any appointment (stats only — no clinical notes via admin routes)

### Messages
- Patient ↔ Doctor only (no patient-to-patient or doctor-to-doctor)
- Requires at least one **confirmed or completed** appointment between the pair
- Cannot read another user's message thread

### Medical records
- `GET /patient/records` — patient role only
- Records scoped to the authenticated patient's consultations
- Admin middleware blocks access entirely

### Consultations
- Doctor role only
- Doctor must own the appointment (`doctor_id` match)
- One consultation record per appointment

## Audit logging

Sensitive actions are written to `audit_logs`:

| Action | When |
|--------|------|
| `auth.login` / `auth.logout` / `auth.register` | Authentication events |
| `password.reset_requested` / `password.reset_completed` | Password reset flow |
| `appointment.created` / `rescheduled` / `cancelled` | Booking changes |
| `consultation.created` | Doctor saves clinical notes |
| `message.sent` / `message.thread_viewed` | Messaging |
| `patient.records_viewed` | Patient opens medical records |
| `doctor.verified` / `doctor.suspended` / `doctor.reactivated` | Admin actions |

Admins can review logs: `GET /api/admin/audit-logs`

## Doctor moderation

| Field | Effect |
|-------|--------|
| `is_verified = false` | Hidden from public doctor list; cannot be booked |
| `is_suspended = true` | Hidden from public list; cannot be booked; admin must reactivate |

## Rate limits

| Route group | Limit |
|-------------|-------|
| `/login`, `/register`, `/forgot-password`, `/reset-password` | 10/min per IP |
| `/symptom-check` | 30/min per IP |

## Production checklist

- [ ] Set `APP_DEBUG=false`
- [ ] Use HTTPS in production
- [ ] Configure real mail driver for password reset emails
- [ ] Use MySQL/PostgreSQL instead of SQLite for production
- [ ] Rotate `APP_KEY` and use strong database credentials
- [ ] Enable queue worker for future notification jobs
