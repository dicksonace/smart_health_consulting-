# Windows Setup Guide — Smart Health Consulting

Complete setup for **Windows 10/11**: Laravel API + Flutter mobile app + Android emulator.

---

## What you need

| Tool | Version | Download |
|------|---------|----------|
| PHP | 8.3+ | https://windows.php.net/download/ |
| Composer | 2.x | https://getcomposer.org/download/ |
| Git | Latest | https://git-scm.com/download/win |
| Flutter | 3.22+ stable | https://docs.flutter.dev/get-started/install/windows |
| Android Studio | Latest | https://developer.android.com/studio |
| Java JDK | 17 | Installed with Android Studio |

> **Important:** Laravel 13 needs **PHP 8.3+**. If you use XAMPP, upgrade to a version that includes PHP 8.3, or install standalone PHP 8.3 from windows.php.net.

---

## Step 1 — Install PHP 8.3+

### Option A — Standalone PHP (recommended)

1. Download **PHP 8.3+** ZIP (Thread Safe) from https://windows.php.net/download/
2. Extract to `C:\php` (or `C:\tools\php`)
3. Copy `php.ini-development` → `php.ini`
4. Edit `php.ini` and uncomment (remove `;`):
   ```ini
   extension=curl
   extension=fileinfo
   extension=mbstring
   extension=openssl
   extension=pdo_sqlite
   extension=sqlite3
   ```
5. Add `C:\php` to your **PATH**:
   - Press `Win + S` → search **Environment Variables**
   - Under **User variables** → **Path** → **Edit** → **New** → `C:\php`
6. Open a **new** PowerShell window and verify:
   ```powershell
   php -v
   ```

### Option B — Chocolatey

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install php --version=8.3.0 -y
refreshenv
php -v
```

---

## Step 2 — Install Composer

1. Download and run **Composer-Setup.exe** from https://getcomposer.org/download/
2. Point it to your `php.exe` (e.g. `C:\php\php.exe`)
3. Verify:
   ```powershell
   composer -V
   ```

---

## Step 3 — Install Flutter

1. Download the Flutter SDK ZIP: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\src\flutter` (avoid `C:\Program Files\` — spaces cause issues)
3. Add `C:\src\flutter\bin` to **PATH** (same Environment Variables dialog)
4. Open a **new** PowerShell window:
   ```powershell
   flutter doctor
   ```

Fix anything `flutter doctor` flags before continuing.

---

## Step 4 — Install Android Studio + SDK

1. Download and install **Android Studio**: https://developer.android.com/studio
2. During setup, install:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (AVD)
3. After install, open **Android Studio** → **Settings** (or **File → Settings**)
4. Go to **Languages & Frameworks → Android SDK**:
   - **SDK Platforms** tab: check **Android 14 (API 34)**
   - **SDK Tools** tab: check:
     - Android SDK Build-Tools
     - Android SDK Command-line Tools
     - Android Emulator
     - Android SDK Platform-Tools
     - NDK (Side by side) 28.2.x
5. Click **Apply** and wait for downloads

### Set ANDROID_HOME

1. **Environment Variables** → **User variables** → **New**:
   - Name: `ANDROID_HOME`
   - Value: `C:\Users\<YourUsername>\AppData\Local\Android\Sdk`
2. Edit **Path** → add these entries:
   ```
   %ANDROID_HOME%\platform-tools
   %ANDROID_HOME%\emulator
   %ANDROID_HOME%\cmdline-tools\latest\bin
   ```
3. Open a **new** PowerShell window:
   ```powershell
   flutter doctor --android-licenses
   ```
   Type `y` to accept all licenses.

---

## Step 5 — Create an Android emulator

### Option A — Android Studio GUI (easiest)

1. Open **Android Studio** → **More Actions** → **Virtual Device Manager**
2. **Create Device** → choose **Pixel 7** → **Next**
3. Download system image: **API 34**, **Google APIs**, **x86_64** (Intel/AMD PC)
4. **Finish**, then click **▶** to start the emulator
5. Name it `SmartHealth_Emulator` when prompted (optional)

### Option B — Command line (PowerShell)

```powershell
# Accept licenses
sdkmanager --licenses

# Install components
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "emulator" `
  "system-images;android-34;google_apis;x86_64" "ndk;28.2.13676358"

# Create emulator
avdmanager create avd -n SmartHealth_Emulator -k "system-images;android-34;google_apis;x86_64" -d pixel_7 --force

# Launch
flutter emulators --launch SmartHealth_Emulator
```

Verify:
```powershell
flutter devices
```

---

## Step 6 — Clone the project

```powershell
cd C:\Users\<YourUsername>\Desktop
git clone https://github.com/dicksonace/smart_health_consulting-.git
cd smart_health_consulting-
```

---

## Step 7 — Set up the API (Laravel)

Open **PowerShell** (Terminal 1):

```powershell
cd C:\Users\<YourUsername>\Desktop\smart_health_consulting-\api

composer install
copy .env.example .env
php artisan key:generate
New-Item -ItemType File -Path database\database.sqlite -Force
php artisan migrate:fresh --seed
php artisan serve
```

API runs at: **http://127.0.0.1:8000**

Test in browser:
- http://127.0.0.1:8000/api/health

Keep this terminal open.

---

## Step 8 — Run the mobile app

Open a **second PowerShell** window (Terminal 2):

```powershell
cd C:\Users\<YourUsername>\Desktop\smart_health_consulting-\mobile

flutter pub get
flutter emulators --launch SmartHealth_Emulator   # skip if emulator already running
flutter run
```

The app connects to `http://10.0.2.2:8000/api` on the Android emulator (maps to your PC's localhost).

---

## Step 9 — Login and test

| Role | Email | Password |
|------|-------|----------|
| Patient | `alice@health.test` | `password` |
| Doctor | `sarah.chen@health.test` | `password` |
| Admin | `admin@health.test` | `password` |

Or use **Quick Demo** buttons on the login screen.

---

## Running both projects (daily workflow)

**Terminal 1 — API:**
```powershell
cd C:\path\to\smart_health_consulting-\api
php artisan serve
```

**Terminal 2 — Mobile:**
```powershell
cd C:\path\to\smart_health_consulting-\mobile
flutter run
```

---

## Physical Android phone (optional)

1. Enable **Developer options** → **USB debugging** on the phone
2. Connect via USB; allow debugging when prompted
3. Run `flutter devices` — phone should appear
4. Find your PC IP: `ipconfig` → look for **IPv4 Address** (e.g. `192.168.1.10`)
5. Edit `mobile\lib\api\api_config.dart` — change base URL to:
   ```dart
   return 'http://192.168.1.10:8000/api';
   ```
6. Start API bound to all interfaces:
   ```powershell
   php artisan serve --host=0.0.0.0 --port=8000
   ```
7. Allow port 8000 through **Windows Firewall** if prompted
8. Run `flutter run`

---

## Windows troubleshooting

| Problem | Fix |
|---------|-----|
| `php` not recognized | Add PHP folder to PATH; open a **new** terminal |
| `composer install` — PHP version error | Install PHP 8.3+; run `php -v` to confirm |
| `php artisan` — sqlite extension missing | Uncomment `extension=pdo_sqlite` and `extension=sqlite3` in `php.ini` |
| `flutter doctor` — Android licenses | Run `flutter doctor --android-licenses` |
| Gradle / NDK build fails | Open Android Studio → SDK Manager → install **NDK 28.2**; or run `sdkmanager "ndk;28.2.13676358"` |
| App can't reach API | Ensure `php artisan serve` is running in Terminal 1 |
| `execution policy` blocks scripts | Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| Emulator very slow | Enable **Hardware acceleration** (Intel HAXM or Windows Hypervisor Platform) in Windows Features |
| `copy` vs `cp` | On Windows use `copy .env.example .env` not `cp` |
| `touch` not found | Use `New-Item -ItemType File database\database.sqlite -Force` |

---

## Useful commands reference

```powershell
php -v                          # Check PHP version
composer -V                     # Check Composer
flutter doctor                  # Check Flutter + Android setup
flutter devices                 # List connected devices / emulators
flutter emulators               # List available emulators
flutter emulators --launch SmartHealth_Emulator
php artisan test                # Run API tests (from api/ folder)
php artisan migrate:fresh --seed  # Reset database with demo data
```
