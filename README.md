# Notes App

A simple cross-platform Notes application with:

- **Flutter frontend**
  - Firebase Authentication (email/password)
  - Offline caching using Hive (notes available without internet once logged in)
  - BLoC state management
  - Syncs with backend when connection is available

- **Backend API** (Django/FastAPI/Express - adjust as needed)
  - REST endpoints for CRUD operations on notes
  - JWT authentication (integrates with Firebase ID tokens)
  - Stores notes in database (SQLite/Postgres/MySQL configurable)

---

## ✨ Features

- Create, update, delete, and pin notes.
- Works offline: cached notes are stored locally in Hive boxes.
- Automatic sync: when online, local changes are sent to backend.
- Per-user data separation: notes are stored per Firebase UID.

---

##  Frontend (Flutter)

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Xcode / Android Studio (for iOS/Android emulators)
- Firebase project set up with:
  - Authentication → Email/Password enabled
  - iOS + Android apps added
  - `google-services.json` / `GoogleService-Info.plist`
- Backend server running (see below)

### Run
```bash
cd frontend
flutter pub get
flutter run


##  Backend (API)

### Prerequisites

Python 3.10+ (for FastAPI/Django)
or Node.js 18+ (for Express)

SQLite (default) or PostgreSQL

### Run
```bash
cd frontend
flutter pub get
flutter run

