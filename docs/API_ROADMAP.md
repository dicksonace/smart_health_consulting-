# API Roadmap — Smart Health Consulting

## ✅ Completed (v1.0 — ready to use)

### Core API
- [x] Sanctum authentication (register, login, logout, `/user`)
- [x] Patient / doctor / admin roles
- [x] Doctors list + profile + availability
- [x] Appointments (book, reschedule, cancel) with slot locking
- [x] Consultations + prescriptions
- [x] Messages + conversations
- [x] Symptom checker (rule-based triage)
- [x] Notifications
- [x] Feedback + doctor rating average
- [x] Admin stats + doctor verification

### Security hardening (v1.0)
- [x] Rate limiting on auth + symptom check
- [x] Message authorization (appointment relationship required)
- [x] Appointment policies (ownership checks)
- [x] Doctor suspend / reactivate (admin)
- [x] Unverified/suspended doctors blocked from booking
- [x] Audit log for sensitive actions
- [x] Password reset API (`/forgot-password`, `/reset-password`)
- [x] Form Request validation classes
- [x] 25 automated API tests

### Mobile integration
- [x] Flutter app wired to API (`AppStore` + `ApiClient`)
- [x] Patient, doctor, admin flows
- [x] Android emulator + network config

### Documentation
- [x] README setup (macOS, Windows, Linux)
- [x] `SETUP_WINDOWS.md`
- [x] `API_ENDPOINTS.md`, `DATABASE_SCHEMA.md`
- [x] `API_SECURITY.md`, `API_TESTING.md`
- [x] Postman collection

---

## 🔜 Phase 4 — Real-time & notifications (future)

- [ ] WebSocket chat (Laravel Reverb / Pusher)
- [ ] Push notifications (FCM)
- [ ] Email/SMS appointment reminders (Laravel scheduler)
- [ ] Live calendar slot updates

## 🔜 Phase 5 — Advanced (future)

- [ ] Video calls (WebRTC / Jitsi)
- [ ] File upload endpoint (message attachments, lab results)
- [ ] AI-enhanced symptom checker
- [ ] `flutter_secure_storage` for tokens
- [ ] OpenAPI/Swagger auto-generated docs

---

## Version history

| Version | Date | Notes |
|---------|------|-------|
| 1.0.0 | 2026-07 | MVP complete — API hardened, mobile integrated, docs ready |
