# API Roadmap — Smart Health Consulting

## ✅ v1.0 — MVP (complete)

Core API, mobile integration, security hardening, setup docs.

## ✅ v1.1 — Phase 4 & 5 (complete)

### Phase 4 — Real-time & notifications
- [x] Real-time event polling (`/api/realtime/poll`)
- [x] Live slot updates when appointments are booked
- [x] Chat near-real-time via 3s polling + local notifications
- [x] Email appointment reminders (24h + 1h) via scheduler
- [x] Push notification service (FCM-ready)
- [x] Device token registration

### Phase 5 — Advanced features
- [x] Jitsi video consultations (`/api/appointments/{id}/video-room`)
- [x] Symptom checker disclaimer + suggested actions
- [x] Secure token storage on mobile
- [x] 32 API tests + Flutter tests
- [x] Release APK build documented

See [PHASE_4_5.md](PHASE_4_5.md) for setup and usage.

---

## 🔜 Future enhancements

- [ ] Laravel Reverb WebSockets (replace polling)
- [ ] Full Firebase FCM with `google-services.json`
- [ ] SMS reminders (Twilio / Africa's Talking)
- [ ] Agora branded video SDK
- [ ] OpenAI conversational symptom flow
- [ ] File upload for message attachments

---

| Version | Date | Notes |
|---------|------|-------|
| 1.0.0 | 2026-07 | MVP + security hardening |
| 1.1.0 | 2026-07 | Phase 4 & 5 complete |
