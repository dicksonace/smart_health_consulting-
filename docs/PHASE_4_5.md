# Phase 4 & 5 — Real-Time, Notifications, Video & Polish

## Phase 4 — Real-time & notifications ✅

### API
| Feature | Endpoint / command |
|---------|-------------------|
| Real-time poll | `GET /api/realtime/poll?since=ISO8601&doctor_id=` |
| Device token (FCM) | `POST /api/device-token` |
| Email reminders | `php artisan appointments:send-reminders` (scheduled every 15 min) |
| Push notifications | `PushNotificationService` (logs when `FCM_SERVER_KEY` not set) |

Events emitted:
- `new_message` — when a chat message is sent
- `slot_booked` — when a patient books a doctor slot (live calendar refresh)
- `appointment_booked` / `appointment_confirmed`

### Mobile
- **Chat polling** — refreshes messages every 3 seconds in chat screen
- **Booking polling** — refreshes slots when another patient books
- **Local notifications** — alerts for new messages while app is open
- **Secure token storage** — `flutter_secure_storage` with SharedPreferences fallback

### Optional setup (production)
```env
FCM_SERVER_KEY=your-firebase-server-key
```

Run scheduler for email reminders:
```bash
php artisan schedule:work
```

---

## Phase 5 — Video, AI polish & deployment ✅

### API
| Feature | Endpoint |
|---------|----------|
| Jitsi video room | `GET /api/appointments/{id}/video-room` |
| AI symptom disclaimer | `POST /api/symptom-check` returns `disclaimer` + `suggested_actions` |

Video room opens **5 minutes before** scheduled time via public Jitsi (`meet.jit.si`).

### Mobile
- **Video calls** — WebView loads Jitsi room when `can_join` is true
- **Symptom checker** — shows disclaimer banner + suggested actions from API
- **Secure storage** — auth tokens encrypted on device

### Build release APK
```bash
cd mobile
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Deploy API (example)
```bash
# On server
composer install --no-dev
php artisan migrate --force
php artisan config:cache
php artisan serve --host=0.0.0.0 --port=8000
# Or use nginx + php-fpm; set APP_DEBUG=false
```

---

## Test coverage

```bash
cd api && php artisan test   # 32 tests
cd mobile && flutter test
```

---

## What's next (optional)

- Full Firebase FCM integration with `google-services.json`
- Laravel Reverb for true WebSockets (replace polling)
- Twilio/Africa's Talking SMS reminders
- Agora SDK for branded video (instead of Jitsi)
