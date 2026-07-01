# Smart Health Consulting

Monorepo for the **Smart Health Consulting and Appointment Booking System** — Flutter mobile app + Laravel REST API.

## Structure

| Folder | Stack | Purpose |
|--------|-------|---------|
| [`api/`](api/) | Laravel 13, Sanctum, SQLite | REST API backend |
| [`mobile/`](mobile/) | Flutter 3.x | Patient / Doctor / Admin mobile app |
| [`docs/`](docs/) | Markdown | Project plan, schema, API reference |

---

## Prerequisites

Install these **before** cloning:

| Tool | Version | Notes |
|------|---------|-------|
| **PHP** | 8.3+ (8.5 recommended) | Laravel 13 requires PHP 8.3+. XAMPP PHP 8.2 is too old. |
| **Composer** | 2.x | PHP dependency manager |
| **Flutter** | 3.22+ stable | Mobile framework |
| **Android SDK** | API 34+ | For Android emulator or device |
| **Java JDK** | 17 | Required by Android Gradle builds |

### Install prerequisites (macOS)

```bash
# Homebrew (if not installed): https://brew.sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# PHP 8.5 + Composer
brew install php composer

# Flutter
brew install --cask flutter

# Android command-line tools + Java 17
brew install --cask android-commandlinetools
brew install openjdk@17

# Add to ~/.zshrc (or ~/.bashrc), then restart terminal:
export PATH="/opt/homebrew/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export ANDROID_HOME="$HOME/Library/Android/sdk"   # or Homebrew path below
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

> **Homebrew Android SDK path** (if you installed via `brew install --cask android-commandlinetools`):
> `export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"`

### Install prerequisites (Windows)

See the full walkthrough: **[docs/SETUP_WINDOWS.md](docs/SETUP_WINDOWS.md)**

#### 1. PHP 8.3+

Download from https://windows.php.net/download/ (Thread Safe ZIP), extract to `C:\php`, and add to PATH.

Edit `php.ini` — uncomment these extensions:
```ini
extension=curl
extension=fileinfo
extension=mbstring
extension=openssl
extension=pdo_sqlite
extension=sqlite3
```

Verify in **PowerShell**:
```powershell
php -v
```

> XAMPP users: default PHP 8.2 is too old for Laravel 13. Upgrade XAMPP or install standalone PHP 8.3+.

#### 2. Composer

Download **Composer-Setup.exe** from https://getcomposer.org/download/ and run the installer.

```powershell
composer -V
```

#### 3. Flutter

1. Download SDK from https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\src\flutter` (no spaces in path)
3. Add `C:\src\flutter\bin` to PATH

```powershell
flutter doctor
```

#### 4. Android Studio + SDK

1. Install https://developer.android.com/studio
2. In **Settings → Android SDK**, install **API 34** and SDK tools (Emulator, Platform-Tools, NDK 28.2)
3. Set environment variables (**System Properties → Environment Variables**):

| Variable | Value |
|----------|-------|
| `ANDROID_HOME` | `C:\Users\<you>\AppData\Local\Android\Sdk` |
| PATH (add) | `%ANDROID_HOME%\platform-tools` |
| PATH (add) | `%ANDROID_HOME%\emulator` |
| PATH (add) | `%ANDROID_HOME%\cmdline-tools\latest\bin` |

4. Accept Android licenses:
```powershell
flutter doctor --android-licenses
```

#### 5. Git

Download from https://git-scm.com/download/win (used to clone the repo).

### Install prerequisites (Linux)

```bash
# Ubuntu/Debian example
sudo apt update
sudo apt install php8.3 php8.3-sqlite3 php8.3-mbstring php8.3-xml php8.3-curl unzip curl git

# Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Flutter — follow https://docs.flutter.dev/get-started/install/linux
# Android Studio — https://developer.android.com/studio
```

### Verify installations

```bash
php -v          # should show 8.3+
composer -V
flutter doctor  # fix any issues it reports
```

---

## Clone the repository

```bash
git clone https://github.com/dicksonace/smart_health_consulting-.git
cd smart_health_consulting-
```

---

## 1. API setup (Laravel)

### macOS / Linux

```bash
cd api

# Use Homebrew PHP on macOS if system PHP is too old
export PATH="/opt/homebrew/bin:$PATH"

composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate:fresh --seed
php artisan serve
```

### Windows (PowerShell)

```powershell
cd api

composer install
copy .env.example .env
php artisan key:generate
New-Item -ItemType File -Path database\database.sqlite -Force
php artisan migrate:fresh --seed
php artisan serve
```

The API runs at **`http://127.0.0.1:8000`**.

| Check | URL |
|-------|-----|
| Health | http://127.0.0.1:8000/api/health |
| Doctors list | http://127.0.0.1:8000/api/doctors |

Run tests: `php artisan test` (25 tests)

See [docs/API_ENDPOINTS.md](docs/API_ENDPOINTS.md) for the full API reference.
See [docs/API_SECURITY.md](docs/API_SECURITY.md) for security model.

---

## 2. Android emulator setup

You need an emulator (or a physical Android device) to run the mobile app.

### Option A — Android Studio (easiest)

1. Open **Android Studio** → **More Actions** → **Virtual Device Manager**
2. Click **Create Device** → pick **Pixel 7** (or any phone)
3. Download a system image (**API 34**, Google APIs, arm64 on Apple Silicon / x86_64 on Intel)
4. Finish and click **▶** to launch the emulator

### Option B — Command line (macOS / Linux)

```bash
# Accept licenses (required once)
yes | sdkmanager --licenses

# Install SDK components
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "emulator" \
  "system-images;android-34;google_apis;arm64-v8a" "ndk;28.2.13676358"

# Create an emulator (name it SmartHealth_Emulator)
avdmanager create avd -n SmartHealth_Emulator -k "system-images;android-34;google_apis;arm64-v8a" \
  -d pixel_7 --force

# List emulators
flutter emulators

# Launch emulator
flutter emulators --launch SmartHealth_Emulator
# or: emulator -avd SmartHealth_Emulator
```

> On **Intel Mac/PC**, replace `arm64-v8a` with `x86_64` in the system image and AVD commands.

### Option C — Command line (Windows PowerShell)

```powershell
sdkmanager --licenses

sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "emulator" `
  "system-images;android-34;google_apis;x86_64" "ndk;28.2.13676358"

avdmanager create avd -n SmartHealth_Emulator -k "system-images;android-34;google_apis;x86_64" -d pixel_7 --force

flutter emulators --launch SmartHealth_Emulator
```

> Full Windows emulator guide: [docs/SETUP_WINDOWS.md](docs/SETUP_WINDOWS.md#step-5--create-an-android-emulator)

### Verify emulator is running

```bash
flutter devices
# Should show something like: emulator-5554 • android-arm64 • Android 14 (API 34)
```

---

## 3. Mobile app setup (Flutter)

```bash
cd mobile
flutter pub get
flutter analyze
```

### Run on Android emulator

**Start the API first** (see section 1), then in a second terminal:

```bash
cd mobile
flutter run
# or target a specific device:
flutter run -d emulator-5554
```

The app connects to the API automatically:
- **Android emulator** → `http://10.0.2.2:8000/api` (maps to your machine's localhost)
- **iOS simulator / desktop** → `http://127.0.0.1:8000/api`

Config file: [`mobile/lib/api/api_config.dart`](mobile/lib/api/api_config.dart)

### Run on a physical Android phone

1. Enable **Developer options** → **USB debugging** on the phone
2. Connect via USB, run `flutter devices` to confirm it's detected
3. Find your PC's local IP (e.g. `192.168.1.10`)
4. Update `api_config.dart` base URL to `http://192.168.1.10:8000/api`
5. Start API with: `php artisan serve --host=0.0.0.0 --port=8000`
6. Run `flutter run`

---

## Running both projects together

Open **two terminals**:

### macOS / Linux

**Terminal 1 — API:**
```bash
cd api
export PATH="/opt/homebrew/bin:$PATH"   # macOS only, if needed
php artisan serve
```

**Terminal 2 — Mobile:**
```bash
cd mobile
flutter emulators --launch SmartHealth_Emulator   # skip if already running
flutter run -d emulator-5554
```

### Windows (PowerShell)

**Terminal 1 — API:**
```powershell
cd C:\path\to\smart_health_consulting-\api
php artisan serve
```

**Terminal 2 — Mobile:**
```powershell
cd C:\path\to\smart_health_consulting-\mobile
flutter emulators --launch SmartHealth_Emulator   # skip if already running
flutter run
```

Quick test flow:
1. Login as patient (`alice@health.test` / `password`) or tap **Quick Demo → Patient**
2. Try **Symptom Checker**, **Book Appointment**, **Messages**, **Medical Records**
3. Log out → login as doctor (`sarah.chen@health.test`) → complete a consultation

---

## Demo accounts

Password for all accounts: **`password`**

| Role | Email |
|------|-------|
| Admin | `admin@health.test` |
| Patient | `alice@health.test`, `bob@health.test` |
| Doctor | `sarah.chen@health.test`, `james.wilson@health.test` |

---

## Documentation

| File | Description |
|------|-------------|
| [docs/SETUP_WINDOWS.md](docs/SETUP_WINDOWS.md) | **Full Windows setup guide** (PHP, Flutter, emulator, API) |
| [docs/PHASE_4_5.md](docs/PHASE_4_5.md) | Phase 4 & 5: real-time, video, reminders |
| [docs/API_ROADMAP.md](docs/API_ROADMAP.md) | What's done vs planned (v1.1 complete) |
| [docs/API_SECURITY.md](docs/API_SECURITY.md) | RBAC, audit logs, rate limits |
| [docs/API_TESTING.md](docs/API_TESTING.md) | Run tests, curl examples, Postman |
| [docs/PROJECT_WORK_PLAN.md](docs/PROJECT_WORK_PLAN.md) | Phased plan: UI → API → Integration |
| [docs/PHASE_1_UI_CHECKLIST.md](docs/PHASE_1_UI_CHECKLIST.md) | Screen-by-screen UI checklist |
| [docs/DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) | Database tables (12 tables) |
| [docs/API_ENDPOINTS.md](docs/API_ENDPOINTS.md) | Full REST API reference |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `composer install` fails on PHP version (macOS) | Use PHP 8.3+: `brew install php` then `export PATH="/opt/homebrew/bin:$PATH"` |
| `composer install` fails on PHP version (Windows) | Install PHP 8.3+ from windows.php.net; add to PATH; run `php -v` in a new terminal |
| `php` / `flutter` not recognized (Windows) | Add install folders to PATH via Environment Variables; open a **new** PowerShell window |
| SQLite extension missing (Windows) | In `php.ini`, uncomment `extension=pdo_sqlite` and `extension=sqlite3` |
| Gradle NDK install error | Run `sdkmanager "ndk;28.2.13676358"` or delete corrupted NDK folder and reinstall |
| App can't reach API on emulator | Ensure `php artisan serve` is running; Android uses `10.0.2.2` not `127.0.0.1` |
| Navigation bounces back to home | Fixed in `main.dart` — router must be created once at startup |
| `flutter doctor` Android errors | Run `flutter doctor --android-licenses` and accept all |
| Emulator not listed | Run `flutter emulators --launch <name>` then `flutter devices` |
| Emulator slow on Windows | Enable **Windows Hypervisor Platform** in Windows Features; use x86_64 system image |

---

## API endpoints (summary)

- `GET /api/health` — Health check
- `POST /api/login` / `POST /api/register` — Authentication
- `GET /api/doctors` — List verified doctors
- `GET/POST /api/appointments` — Book & manage appointments
- `POST /api/consultations` — Doctor notes + prescriptions
- `GET/POST /api/messages` — Patient–doctor chat
- `POST /api/symptom-check` — Rule-based triage
- `GET /api/admin/stats` — Admin dashboard data

Full reference: [docs/API_ENDPOINTS.md](docs/API_ENDPOINTS.md)
