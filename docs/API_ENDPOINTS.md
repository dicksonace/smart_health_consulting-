# Smart Health Consulting — API Reference

Base URL: `http://127.0.0.1:8000/api`

Authentication: **Bearer token** (Laravel Sanctum) on protected routes.

---

## Demo accounts (after `php artisan migrate:fresh --seed`)

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@health.test` | `password` |
| Patient | `alice@health.test` | `password` |
| Patient | `bob@health.test` | `password` |
| Doctor | `sarah.chen@health.test` | `password` |
| Doctor | `james.wilson@health.test` | `password` |
| Doctor | `emily.park@health.test` | `password` (unverified) |

---

## Public endpoints

### Health check
```
GET /health
```

### Register
```
POST /register
```
Body:
```json
{
  "name": "Ama Mensah",
  "email": "ama@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "phone": "+233241234567",
  "role": "patient",
  "date_of_birth": "1995-03-15",
  "gender": "female",
  "blood_group": "O+",
  "allergies": "Penicillin"
}
```

Doctor registration — add: `specialty`, `consultation_fee`, `qualifications`, `bio`.

### Login
```
POST /login
```
```json
{ "email": "alice@health.test", "password": "password" }
```
Returns `{ "user": {...}, "token": "..." }`.

### Forgot password
```
POST /forgot-password
```
```json
{ "email": "alice@health.test" }
```
When `APP_DEBUG=true`, response includes `debug_token` for testing.

### Reset password
```
POST /reset-password
```
```json
{
  "email": "alice@health.test",
  "token": "token-from-forgot-password",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

### Symptom check (rule-based triage)
```
POST /symptom-check
```
```json
{ "symptoms": ["skin rash", "itching"] }
```

### List doctors (verified only)
```
GET /doctors?specialty=Dermatology&min_rating=4
```

### Doctor profile + available slots
```
GET /doctors/{id}
```

---

## Authenticated endpoints

Header: `Authorization: Bearer {token}`

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/user` | Current user + profile |
| POST | `/logout` | Revoke token |

### Patient (`role:patient`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/patient/profile` | Patient profile |
| PATCH | `/patient/profile` | Update profile |
| GET | `/patient/records` | Consultation history |
| GET | `/patient/prescriptions` | All prescriptions |

### Doctor (`role:doctor`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/doctor/profile` | Doctor profile |
| PATCH | `/doctor/profile` | Update profile |
| GET | `/doctor/availability` | List slots |
| POST | `/doctor/availability` | Create slot |
| PATCH | `/doctor/availability/{id}` | Update slot |
| DELETE | `/doctor/availability/{id}` | Delete slot |

### Appointments (patient, doctor, admin)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/appointments` | List (scoped by role) |
| POST | `/appointments` | Book (patient only) |
| PATCH | `/appointments/{id}` | Reschedule |
| DELETE | `/appointments/{id}` | Cancel |

Book appointment body:
```json
{
  "doctor_id": 1,
  "availability_id": 3,
  "type": "video",
  "reason": "Follow-up visit",
  "urgency": "low"
}
```

### Consultations (doctor)
```
POST /consultations
```
```json
{
  "appointment_id": 1,
  "diagnosis": "Contact dermatitis",
  "notes": "Mild rash on forearms",
  "recommendations": "Avoid irritants",
  "prescriptions": [
    {
      "medicine_name": "Hydrocortisone 1%",
      "dosage": "Apply thin layer",
      "duration": "7 days",
      "instructions": "Twice daily"
    }
  ]
}
```

### Messages
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/conversations` | Conversation list |
| GET | `/messages/{userId}` | Thread with user |
| POST | `/messages` | Send message |

### Real-time (Phase 4)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/realtime/poll` | Poll events since timestamp (`?since=ISO8601&doctor_id=`) |
| POST | `/device-token` | Register FCM push token |
| DELETE | `/device-token` | Remove FCM token |

Event types: `new_message`, `slot_booked`, `appointment_booked`, `appointment_confirmed`

### Video (Phase 5)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/appointments/{id}/video-room` | Jitsi room URL (opens 5 min before) |

### Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications` | User notifications |
| PATCH | `/notifications/{id}/read` | Mark as read |

### Feedback (patient)
```
POST /feedback
```
```json
{ "appointment_id": 1, "rating": 5, "comment": "Great consultation" }
```

### Admin (`role:admin`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/stats` | Platform statistics |
| GET | `/admin/doctors` | All doctors (filter: `?is_verified=0&is_suspended=0`) |
| GET | `/admin/audit-logs` | Security audit trail (`?action=auth.login`) |
| PATCH | `/admin/doctors/{id}/verify` | Approve doctor |
| PATCH | `/admin/doctors/{id}/suspend` | Suspend doctor |
| PATCH | `/admin/doctors/{id}/reactivate` | Reactivate suspended doctor |

> **Security:** Admin cannot access `/patient/records` or message content. See [API_SECURITY.md](API_SECURITY.md).

### Rate limits

| Routes | Limit |
|--------|-------|
| `/login`, `/register`, `/forgot-password`, `/reset-password` | 10/min per IP |
| `/symptom-check` | 30/min per IP |

---

## Business rules

- **No double-booking:** booking uses DB transaction + row lock on availability slot.
- **Cancel frees slot:** cancelled appointments release the availability slot.
- **RBAC:** patients/doctors/admins only access permitted routes.
- **Messages:** patient ↔ doctor only, with an existing appointment.
- **Doctors:** must be verified and not suspended to appear in public list or accept bookings.
- **Audit log:** sensitive actions recorded in `audit_logs` table.
- **Admin:** sees stats and audit logs but not private medical records.

---

## Quick test (curl)

```bash
# Login
curl -s -X POST http://127.0.0.1:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@health.test","password":"password"}'

# Use token
curl -s http://127.0.0.1:8000/api/appointments \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

*v1.0 — API hardened and ready for production use. See [API_ROADMAP.md](API_ROADMAP.md).*
