# Smart Health Consulting

Monorepo for the Smart Health Consulting platform.

## Structure

- **`api/`** — Laravel 13 REST API (Sanctum auth)
- **`mobile/`** — Flutter mobile app

## Setup

### API (Laravel)

```bash
cd api
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

API base URL: `http://127.0.0.1:8000/api`

### Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

## API Endpoints

- `GET /api/health` — Health check
- `GET /api/user` — Authenticated user (Sanctum token required)
