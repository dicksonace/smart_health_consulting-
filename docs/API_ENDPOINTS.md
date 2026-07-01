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
| GET | `/admin/doctors` | All doctors |
| PATCH | `/admin/doctors/{id}/verify` | Approve doctor |

---

## Business rules

- **No double-booking:** booking uses DB transaction + row lock on availability slot.
- **Cancel frees slot:** cancelled appointments release the availability slot.
- **RBAC:** patients/doctors/admins only access permitted routes.
- **Admin:** sees appointment counts but not private medical notes via dedicated endpoints.

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

*Phase 2 complete — ready for Phase 3 mobile ↔ API connection.*
