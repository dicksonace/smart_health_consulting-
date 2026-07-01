# Database Schema — Smart Health Consulting

Reference for Phase 2 backend work. Derived from project specification §3.6.

---

## Entity Relationship (overview)

```
users ──┬── patients ──┬── appointments ──┬── consultation_records ── prescriptions
        │              │                  │
        │              ├── messages       └── feedback
        │              ├── symptom_checker_logs
        │              └── notifications
        │
        └── doctors ──┬── doctor_availability
                      └── appointments (as provider)
```

---

## Tables

### `users`

Shared authentication for all roles.

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| name | string | |
| email | string unique | |
| password | string | hashed |
| phone | string nullable | |
| role | enum | `patient`, `doctor`, `admin` |
| email_verified_at | timestamp nullable | |
| created_at / updated_at | timestamps | |

---

### `patients`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| user_id | FK → users | |
| date_of_birth | date nullable | |
| gender | string nullable | |
| blood_group | string nullable | |
| allergies | text nullable | |
| medical_summary | text nullable | past conditions |
| created_at / updated_at | timestamps | |

---

### `doctors`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| user_id | FK → users | |
| specialty | string | e.g. General Practice, Dermatology |
| qualifications | text nullable | |
| years_experience | int nullable | |
| consultation_fee | decimal(10,2) | |
| bio | text nullable | |
| is_verified | boolean default false | admin approves |
| rating_avg | decimal(3,2) default 0 | computed from feedback |
| created_at / updated_at | timestamps | |

---

### `doctor_availability`

Real-time slot management — **critical for no double-booking**.

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| doctor_id | FK → doctors | |
| date | date | |
| start_time | time | |
| end_time | time | |
| status | enum | `available`, `booked`, `blocked` |
| created_at / updated_at | timestamps | |

**Index:** `(doctor_id, date, start_time)` unique when status = available/booked

---

### `appointments`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| patient_id | FK → patients | |
| doctor_id | FK → doctors | |
| availability_id | FK → doctor_availability nullable | |
| scheduled_at | datetime | |
| type | enum | `in_person`, `video`, `chat` |
| status | enum | `confirmed`, `completed`, `cancelled`, `no_show` |
| reason | text nullable | from symptom checker or patient |
| urgency | enum nullable | `low`, `medium`, `high`, `emergency` |
| created_at / updated_at | timestamps | |

---

### `consultation_records`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| appointment_id | FK → appointments unique | |
| diagnosis | text nullable | |
| notes | text nullable | doctor's clinical notes |
| recommendations | text nullable | |
| created_at / updated_at | timestamps | |

---

### `prescriptions`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| consultation_record_id | FK | |
| medicine_name | string | |
| dosage | string | |
| duration | string | e.g. "7 days" |
| instructions | text nullable | |
| created_at / updated_at | timestamps | |

---

### `messages`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| sender_id | FK → users | |
| receiver_id | FK → users | |
| body | text | |
| attachment_path | string nullable | |
| read_at | timestamp nullable | |
| created_at / updated_at | timestamps | |

---

### `symptom_checker_logs`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| patient_id | FK → patients | |
| symptoms | json or text | raw input |
| suggested_specialty | string nullable | |
| urgency | enum | `low`, `medium`, `high`, `emergency` |
| created_at / updated_at | timestamps | |

---

### `notifications`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| user_id | FK → users | |
| type | string | `appointment_reminder`, `new_message`, etc. |
| title | string | |
| body | text | |
| read_at | timestamp nullable | |
| created_at / updated_at | timestamps | |

---

### `feedback`

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| appointment_id | FK → appointments unique | |
| rating | tinyint | 1–5 |
| comment | text nullable | |
| created_at / updated_at | timestamps | |

---

### `audit_logs` (security)

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| user_id | FK nullable | |
| action | string | e.g. `record.view`, `appointment.create` |
| subject_type / subject_id | morph nullable | |
| ip_address | string nullable | |
| created_at | timestamp | |

---

## Key business rules

1. **Booking transaction:** Lock availability row → create appointment → set status `booked` (rollback on failure).
2. **Cancel:** Set appointment `cancelled` → set availability `available`.
3. **RBAC:** Middleware checks `role` on every sensitive route.
4. **Admin:** Can query appointments count but joins exclude `consultation_records.notes` and `messages.body`.

---

*Implement in Phase 2 via Laravel migrations.*
