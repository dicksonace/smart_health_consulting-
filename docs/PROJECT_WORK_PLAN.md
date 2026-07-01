# Smart Health Consulting — Project Work Plan

> **Source document:** MOBILE HEALTH CARE APP..docx (GCTU Final Year Project)  
> **Team:** Eleazar Asare · Alexander Wawuko Okpattah  
> **Supervisor:** Mr. Mark Mensah  
> **Repo:** `api/` (Laravel) + `mobile/` (Flutter)

---

## 1. Project Summary

**Smart Health Consulting and Appointment Booking System** is a digital health platform that lets patients:

- Consult with doctors (chat / video)
- Book, reschedule, and cancel appointments in real time
- Receive reminders and manage medical records
- Get guided symptom checking before booking

Doctors manage schedules, consultations, notes, and prescriptions. Administrators oversee the platform without access to private medical data.

### User Roles

| Role | Can do | Cannot do |
|------|--------|-----------|
| **Patient** | Book appointments, message doctors, view own records, symptom checker | View other patients' data |
| **Doctor** | Manage availability, consult patients, write notes & prescriptions | View unrelated patient records |
| **Admin** | Manage doctors, view booking stats & feedback | View private medical records or chat content |

### Core Modules (from project spec)

1. User Registration & Profile Management  
2. Health Consultation / Symptom Checker  
3. Real-Time Appointment Scheduling  
4. Patient–Doctor Communication (chat + video)  
5. Medical Records & Prescriptions  
6. Notifications & Reminders  
7. Feedback & Reporting  
8. Security & Privacy (RBAC, encryption, audit logs)

### AI Components (later phase — not MVP)

- Symptom checker & triage assistant  
- Smart doctor matching  
- No-show prediction  
- Conversational support assistant  
- AI-assisted doctor notes  

---

## 2. Recommended Build Order

We build in **three main waves**, then polish:

```
Phase 1 — Mobile UI (mock data)     ← SEE the app, agree on screens
Phase 2 — Backend API + Database    ← BUILD the brain
Phase 3 — Connect mobile ↔ API      ← MAKE it real
Phase 4 — Real-time & notifications ← LIVE updates
Phase 5 — AI, video, admin polish   ← ADVANCED features
```

### Why UI first?

| Benefit | Explanation |
|---------|-------------|
| **Visual agreement** | Team and supervisor can review screens before backend work |
| **Faster feedback** | Change layout/colors/flow without touching the API |
| **Clear API contract** | Each screen tells us exactly which endpoints we need |
| **Demo-ready early** | Show working app on emulator with sample data |

### Why API second?

| Benefit | Explanation |
|---------|-------------|
| **Single source of truth** | Database and business rules live in one place |
| **Testable independently** | Postman/Insomnia tests before mobile wiring |
| **Security first** | Auth, RBAC, and validation built before real data flows |

### Why connection third?

| Benefit | Explanation |
|---------|-------------|
| **Replace mocks gradually** | One screen at a time — lower risk |
| **Catch mismatches early** | UI expectations vs API responses |
| **Stable foundation** | UI + API both exist before adding WebSockets/video |

---

## 3. Tech Stack (aligned with repo)

| Layer | Technology |
|-------|------------|
| Mobile app | **Flutter** (Dart) |
| Backend API | **Laravel 13** + **Sanctum** (token auth) |
| Database | **MySQL** or **SQLite** (dev) |
| Real-time chat | **Laravel Reverb** or **Pusher** + WebSockets |
| Video calls | **WebRTC** (e.g. Agora, Daily.co, or Jitsi) |
| Push / email / SMS | Laravel Notifications + Mail + SMS provider |
| File storage | Laravel filesystem (prescriptions, lab uploads) |

---

## 4. Phase Breakdown

---

### Phase 0 — Environment & Planning ✅ (mostly done)

**Goal:** Dev machines ready; repo cloned; plan documented.

| Task | Status |
|------|--------|
| Clone GitHub repo | ✅ Done |
| Install Flutter + Android emulator | ✅ Done |
| Document phased work plan | ✅ This file |
| Install PHP, Composer, Laravel deps | ⬜ Todo |
| Choose database (MySQL recommended) | ⬜ Todo |
| Agree on app name, colors, logo | ⬜ Todo |

**Deliverable:** Everyone can run `flutter run` and `php artisan serve`.

---

### Phase 1 — Mobile UI with Mock Data

**Goal:** Complete, navigable Flutter app using **fake/local data** — no API yet.

**Design guidelines (from project spec):**

- Calm healthcare palette: **soft blues + white**
- Large tap targets, simple icons + short labels
- Step-by-step registration (not one long form)
- Patient dashboard: upcoming appointments first
- Doctor dashboard: today's schedule in chronological order
- Chat UI: familiar bubble layout
- Records: timeline view, newest first

#### 1.1 App foundation

- [ ] Folder structure: `screens/`, `widgets/`, `models/`, `theme/`, `mock/`
- [ ] App theme (colors, typography, buttons)
- [ ] Bottom navigation or drawer (role-based after login)
- [ ] Routing (go_router or named routes)

#### 1.2 Auth screens (UI only)

- [ ] Splash screen
- [ ] Login (email + password)
- [ ] Register — step 1: name, email, phone, password
- [ ] Register — step 2: role selection (Patient / Doctor)
- [ ] Register — step 3 (Patient): DOB, gender, blood group, allergies
- [ ] Register — step 3 (Doctor): specialty, qualifications, fee, hours
- [ ] Forgot password (placeholder)

#### 1.3 Patient screens

- [ ] **Dashboard** — upcoming appointment card, quick actions
- [ ] **Symptom checker** — chat-style Q&A → suggested specialty + urgency badge
- [ ] **Find doctors** — list with specialty, rating, fee filters
- [ ] **Doctor profile** — bio, availability preview, "Book" button
- [ ] **Book appointment** — calendar, green = available / gray = taken
- [ ] **Appointment confirmation** — summary + confirm
- [ ] **My appointments** — upcoming / past / cancel / reschedule
- [ ] **Messages** — conversation list
- [ ] **Chat thread** — bubbles, timestamps, attach file button
- [ ] **Video call screen** — placeholder UI + join button
- [ ] **Medical records** — timeline of visits
- [ ] **Record detail** — diagnosis, notes, prescriptions
- [ ] **Prescription view** — download/share placeholder
- [ ] **Notifications panel**
- [ ] **Profile & settings**
- [ ] **Feedback** — star rating + comment after visit

#### 1.4 Doctor screens

- [ ] **Dashboard** — today's appointments list
- [ ] **Appointment detail** — patient summary before visit
- [ ] **Manage availability** — weekly hours + slot editor
- [ ] **Messages** — same chat UI as patient
- [ ] **Consultation room** — notes, diagnosis, prescription form
- [ ] **Patient history** — read-only timeline
- [ ] **Profile & settings**

#### 1.5 Admin screens (basic)

- [ ] **Dashboard** — total bookings, active doctors, feedback summary
- [ ] **Doctor management** — list, approve/suspend (UI only)
- [ ] **Reports** — appointments chart, peak hours (static mock chart)

#### 1.6 Mock data layer

- [ ] `MockData` class: sample users, doctors, appointments, messages, records
- [ ] Simulate login by role (tap "Login as Patient" / "Login as Doctor")
- [ ] Simulate real-time slot removal when booking (local state only)

**Phase 1 deliverable:**  
Full app walkthrough on emulator — every screen reachable with mock data.  
**Review checkpoint:** Supervisor/team sign-off on UI before Phase 2.

**Estimated duration:** 2–3 weeks

---

### Phase 2 — Backend API & Database

**Goal:** Laravel REST API with auth, all core entities, and documented endpoints.

#### 2.1 Database (from project spec §3.6)

| Table | Purpose |
|-------|---------|
| `users` | Shared login: id, name, email, password, phone, role |
| `patients` | Patient profile linked to `users` |
| `doctors` | Doctor profile: specialty, qualifications, fee |
| `doctor_availability` | Date, start/end time, status (available/booked) |
| `appointments` | Patient, doctor, datetime, type, status |
| `consultation_records` | Diagnosis, notes, linked to appointment |
| `prescriptions` | Medicines, dosage, duration |
| `messages` | Sender, receiver, content, read status |
| `symptom_checker_logs` | Symptoms, suggested specialty, urgency |
| `notifications` | Type, content, read status |
| `feedback` | Rating, comment, linked to appointment |

- [ ] Migrations for all tables
- [ ] Eloquent models + relationships
- [ ] Seeders: 5 doctors, 10 patients, sample appointments

#### 2.2 Authentication & authorization

- [ ] Sanctum token registration & login
- [ ] Role middleware: `patient`, `doctor`, `admin`
- [ ] Password hashing, validation
- [ ] Profile update endpoints per role

#### 2.3 API endpoints

**Auth**
- [ ] `POST /api/register`
- [ ] `POST /api/login`
- [ ] `POST /api/logout`
- [ ] `GET  /api/user`

**Patients**
- [ ] `GET/PATCH /api/patient/profile`
- [ ] `GET /api/patient/records`
- [ ] `GET /api/patient/prescriptions`

**Doctors**
- [ ] `GET /api/doctors` (list + filters: specialty, rating)
- [ ] `GET /api/doctors/{id}`
- [ ] `GET/PATCH /api/doctor/profile`
- [ ] `GET/POST/DELETE /api/doctor/availability`

**Appointments**
- [ ] `GET /api/appointments` (role-scoped)
- [ ] `POST /api/appointments` (book — locks slot)
- [ ] `PATCH /api/appointments/{id}` (reschedule)
- [ ] `DELETE /api/appointments/{id}` (cancel — frees slot)

**Consultations**
- [ ] `POST /api/consultations` (notes + diagnosis)
- [ ] `POST /api/prescriptions`

**Messages**
- [ ] `GET /api/conversations`
- [ ] `GET /api/messages/{userId}`
- [ ] `POST /api/messages`

**Symptom checker**
- [ ] `POST /api/symptom-check` (returns specialty + urgency)

**Notifications**
- [ ] `GET /api/notifications`
- [ ] `PATCH /api/notifications/{id}/read`

**Feedback**
- [ ] `POST /api/feedback`

**Admin**
- [ ] `GET /api/admin/stats`
- [ ] `GET/PATCH /api/admin/doctors`

#### 2.4 Business rules (critical)

- [ ] **No double-booking** — DB transaction + unique constraint on slot
- [ ] **Slot freed on cancel** — availability status updated immediately
- [ ] **RBAC** — admin cannot hit patient record endpoints
- [ ] **Audit log** — log login, record access, booking changes

#### 2.5 API documentation

- [ ] Postman collection or OpenAPI (`/docs/api`)
- [ ] Example request/response for each endpoint

**Phase 2 deliverable:**  
All endpoints testable via Postman; seed data in DB.  
**Review checkpoint:** API contract matches Phase 1 screens.

**Estimated duration:** 2–3 weeks

---

### Phase 3 — Connect Mobile ↔ API

**Goal:** Replace mock data with real API calls, screen by screen.

#### 3.1 Mobile infrastructure

- [ ] `api_client.dart` — HTTP wrapper (dio or http)
- [ ] Base URL config (dev: `http://10.0.2.2:8000/api` for Android emulator)
- [ ] Token storage (flutter_secure_storage)
- [ ] Auth state provider (riverpod / bloc / provider)
- [ ] Global error handling + loading states

#### 3.2 Wire screens (recommended order)

| Order | Screen | API used |
|-------|--------|----------|
| 1 | Login / Register | Auth endpoints |
| 2 | Patient profile | Patient profile |
| 3 | Doctor list & profile | Doctors |
| 4 | Book appointment | Availability + appointments |
| 5 | My appointments | Appointments CRUD |
| 6 | Doctor dashboard | Doctor appointments |
| 7 | Manage availability | Doctor availability |
| 8 | Consultation notes | Consultations + prescriptions |
| 9 | Medical records | Patient records |
| 10 | Messages | Messages API |
| 11 | Notifications | Notifications |
| 12 | Feedback | Feedback |
| 13 | Admin dashboard | Admin stats |

- [ ] Remove `MockData` as each screen goes live
- [ ] Pull-to-refresh on lists
- [ ] Empty states & error messages

**Phase 3 deliverable:**  
End-to-end flow: register → book → doctor sees appointment → notes saved → patient views record.

**Estimated duration:** 2 weeks

---

### Phase 4 — Real-Time & Notifications

**Goal:** Live updates and automated alerts.

- [ ] WebSocket connection for chat (instant delivery)
- [ ] Live calendar slot updates when another patient books
- [ ] Push notifications (Firebase Cloud Messaging)
- [ ] Email reminders (24h + 1h before appointment)
- [ ] SMS reminders (optional — Twilio / Africa's Talking)
- [ ] In-app notification badge

**Phase 4 deliverable:**  
Chat feels instant; booking conflict impossible; reminders fire automatically.

**Estimated duration:** 1–2 weeks

---

### Phase 5 — Advanced Features & Polish

**Goal:** Features required for final project demo + report.

#### 5.1 Video consultation

- [ ] Integrate WebRTC provider (Agora / Jitsi)
- [ ] "Join call" button active 5 min before appointment
- [ ] In-call document share (basic)

#### 5.2 AI symptom checker (MVP)

- [ ] Rule-based triage first (urgency keywords: chest pain → emergency)
- [ ] Optional: OpenAI / local LLM for conversational symptom flow
- [ ] **Always show disclaimer:** "Not a diagnosis — guidance only"

#### 5.3 Security hardening

- [ ] HTTPS in production
- [ ] Rate limiting on auth endpoints
- [ ] Encrypt sensitive fields at rest
- [ ] MFA for doctors (optional MVP+)

#### 5.4 Testing & deployment

- [ ] Flutter widget tests for key screens
- [ ] Laravel feature tests for booking + auth
- [ ] Deploy API (Railway, Render, or university server)
- [ ] Build APK for demo

**Estimated duration:** 2–3 weeks

---

## 5. Screen ↔ API Mapping (quick reference)

| Screen | Mock (Phase 1) | API endpoint (Phase 2+) |
|--------|----------------|-------------------------|
| Login | Fake delay | `POST /api/login` |
| Register | Local save | `POST /api/register` |
| Doctor list | Static list | `GET /api/doctors` |
| Book slot | Local state | `POST /api/appointments` |
| Chat | Fake messages | `GET/POST /api/messages` |
| Records | Sample JSON | `GET /api/patient/records` |
| Symptom check | Hardcoded rules | `POST /api/symptom-check` |

---

## 6. Milestones & Timeline (suggested)

| Week | Milestone |
|------|-----------|
| 1 | Phase 0 complete + Phase 1 theme & auth UI |
| 2 | Phase 1 patient screens |
| 3 | Phase 1 doctor + admin UI → **UI review** |
| 4–5 | Phase 2 database + auth + appointments API |
| 6 | Phase 2 messages, records, admin API → **API review** |
| 7–8 | Phase 3 full mobile ↔ API connection |
| 9 | Phase 4 real-time + notifications |
| 10–11 | Phase 5 video, AI MVP, testing |
| 12 | Final demo, documentation, report screenshots |

---

## 7. What We Build First (this week)

Priority order for immediate work:

1. **Finalize UI design** — colors, logo, app icon  
2. **Phase 1.1–1.2** — Flutter theme + auth screens with mock login  
3. **Phase 1.3** — Patient dashboard + booking flow (most important demo path)  
4. **Supervisor review** — screenshots / emulator recording  
5. **Then start Phase 2** — migrations + auth API  

---

## 8. Out of Scope for MVP (add later)

- Full HIPAA/GDPR compliance audit  
- Payment gateway integration  
- Pharmacy system integration  
- Wearable device sync  
- Multi-language support  
- Advanced AI (no-show prediction, note summarization)  

---

## 9. Related Documents

| Document | Purpose |
|----------|---------|
| `docs/PHASE_1_UI_CHECKLIST.md` | Detailed UI task checklist |
| `docs/API_ENDPOINTS.md` | Full API spec (create in Phase 2) |
| `docs/DATABASE_SCHEMA.md` | ERD and table details (create in Phase 2) |
| `README.md` | Setup instructions |

---

*Last updated: June 2026 — update this file as phases complete.*
