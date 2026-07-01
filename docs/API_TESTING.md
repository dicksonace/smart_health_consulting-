# API Testing Guide

## Run all tests

```bash
cd api
php artisan test
```

Expected: **25 tests passing** (core + security suite).

## Run specific suites

```bash
php artisan test --filter=HealthApiTest
php artisan test --filter=HealthApiSecurityTest
```

## Manual testing with curl

### Health check
```bash
curl http://127.0.0.1:8000/api/health
```

### Login
```bash
curl -X POST http://127.0.0.1:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@health.test","password":"password"}'
```

### Authenticated request
```bash
TOKEN="your-token-here"
curl http://127.0.0.1:8000/api/appointments \
  -H "Authorization: Bearer $TOKEN"
```

### Password reset (development)

1. Request reset:
```bash
curl -X POST http://127.0.0.1:8000/api/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@health.test"}'
```

When `APP_DEBUG=true`, the response includes `debug_token` for testing.

2. Reset password:
```bash
curl -X POST http://127.0.0.1:8000/api/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "email":"alice@health.test",
    "token":"TOKEN_FROM_STEP_1",
    "password":"newpassword123",
    "password_confirmation":"newpassword123"
  }'
```

## Postman collection

Import [`docs/postman/Smart_Health_API.postman_collection.json`](postman/Smart_Health_API.postman_collection.json).

Set collection variables:
- `base_url` = `http://127.0.0.1:8000/api`
- `token` = (set automatically after Login request)

## Test coverage summary

| Area | Covered |
|------|---------|
| Health + auth | ✅ |
| Doctor listing (verified only) | ✅ |
| Booking + double-book prevention | ✅ |
| Cancel frees slot | ✅ |
| RBAC (admin/patient/doctor) | ✅ |
| Message authorization | ✅ |
| Consultation ownership | ✅ |
| Suspended/unverified doctors | ✅ |
| Audit logs | ✅ |
| Password reset | ✅ |
| Symptom checker | ✅ |
