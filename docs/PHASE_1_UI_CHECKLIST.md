# Phase 1 — Mobile UI Checklist

Use this alongside `PROJECT_WORK_PLAN.md`. Check items off as screens are built on the emulator.

**Rule for Phase 1:** No API calls. All data comes from `lib/mock/mock_data.dart`.

---

## Design tokens

- [x] Primary color: `#2E86AB` (healthcare blue)
- [x] Background: `#F8FAFB`
- [x] Success (available slot): `#28A745`
- [x] Unavailable slot: `#ADB5BD`
- [x] Urgent badge: `#DC3545`
- [x] Font: system default or **Poppins**
- [x] Min button height: 48px
- [x] Border radius: 12px cards, 8px inputs

---

## Navigation structure

```
App
├── Auth (unauthenticated)
│   ├── Splash
│   ├── Login
│   └── Register (multi-step)
│
├── Patient (bottom nav)
│   ├── Home (dashboard)
│   ├── Appointments
│   ├── Messages
│   └── Profile
│
├── Doctor (bottom nav)
│   ├── Schedule
│   ├── Messages
│   ├── Patients
│   └── Profile
│
└── Admin (drawer)
    ├── Dashboard
    ├── Doctors
    └── Reports
```

---

## Screen checklist

### Auth

| # | Screen | Route | Done |
|---|--------|-------|------|
| 1 | Splash | `/` | ✅ |
| 2 | Login | `/login` | ✅ |
| 3 | Register step 1 — account | `/register` | ✅ |
| 4 | Register step 2 — role | `/register/role` | ✅ |
| 5 | Register step 3 — profile details | `/register/details` | ✅ |
| 6 | Forgot password | `/forgot-password` | ✅ |

**Mock behavior:** "Login as Patient" / "Login as Doctor" buttons for quick demo.

---

### Patient

| # | Screen | Route | Done |
|---|--------|-------|------|
| 7 | Dashboard | `/patient/home` | ✅ |
| 8 | Symptom checker (chat UI) | `/patient/symptom-check` | ✅ |
| 9 | Doctor search & filters | `/patient/doctors` | ✅ |
| 10 | Doctor profile | `/patient/doctors/:id` | ✅ |
| 11 | Book appointment (calendar) | `/patient/book/:doctorId` | ✅ |
| 12 | Booking confirmation | `/patient/book/confirm` | ✅ |
| 13 | My appointments | `/patient/appointments` | ✅ |
| 14 | Appointment detail | `/patient/appointments/:id` | ✅ |
| 15 | Conversation list | `/patient/messages` | ✅ |
| 16 | Chat thread | `/patient/messages/:id` | ✅ |
| 17 | Video call (placeholder) | `/patient/call/:id` | ✅ |
| 18 | Medical records timeline | `/patient/records` | ✅ |
| 19 | Record / prescription detail | `/patient/records/:id` | ✅ |
| 20 | Notifications | `/patient/notifications` | ✅ |
| 21 | Profile & settings | `/patient/profile` | ✅ |
| 22 | Post-visit feedback | `/patient/feedback/:appointmentId` | ✅ |

---

### Doctor

| # | Screen | Route | Done |
|---|--------|-------|------|
| 23 | Dashboard (today's schedule) | `/doctor/home` | ✅ |
| 24 | Appointment detail + patient preview | `/doctor/appointments/:id` | ✅ |
| 25 | Manage availability | `/doctor/availability` | ✅ |
| 26 | Conversation list | `/doctor/messages` | ✅ |
| 27 | Chat thread | `/doctor/messages/:id` | ✅ |
| 28 | Consultation room (notes + Rx) | `/doctor/consult/:id` | ✅ |
| 29 | Patient history | `/doctor/patients/:id` | ✅ |
| 30 | Profile & settings | `/doctor/profile` | ✅ |

---

### Admin

| # | Screen | Route | Done |
|---|--------|-------|------|
| 31 | Admin dashboard | `/admin/home` | ✅ |
| 32 | Doctor list (approve/suspend) | `/admin/doctors` | ✅ |
| 33 | Reports & charts | `/admin/reports` | ✅ |

---

## Mock data to create

```dart
// lib/mock/mock_data.dart — suggested contents

MockUsers       // 1 patient, 1 doctor, 1 admin (demo login)
MockDoctors     // 5 doctors: GP, dermatologist, cardiologist, etc.
MockAppointments // upcoming + past for demo patient
MockMessages    // 2 conversations with sample bubbles
MockRecords     // 3 consultation history entries
MockPrescriptions
MockNotifications // 5 sample alerts
MockSlots       // doctor availability for calendar UI
```

---

## Demo flow (for supervisor review)

Record this path on the emulator:

1. Open app → Splash → Login as **Patient**
2. Dashboard shows upcoming appointment
3. Tap **Symptom Checker** → answer questions → see "See a Dermatologist" suggestion
4. Tap **Book Appointment** → pick doctor → green slot → confirm
5. Open **Messages** → send a mock message
6. View **Medical Records** → expand a visit
7. Log out → Login as **Doctor**
8. See new appointment on schedule → open consultation → add notes + prescription
9. Log out → Login as **Admin** → view stats

---

## Phase 1 done when

- [ ] All 33 screens exist and are navigable
- [ ] Mock demo flow works without crashes
- [ ] Theme is consistent across all screens
- [ ] Team + supervisor approve UI
- [ ] Screenshots saved to `docs/screenshots/` for project report

**Next step:** Start Phase 2 — Laravel migrations matching `PROJECT_WORK_PLAN.md` §2.1
