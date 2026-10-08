# 🏟️ Sporta — Smart Sports Field Reservation Platform

> A full-stack mobile application for booking sports fields in real time.
> Players discover and reserve venues, join matches, create teams, chat
> instantly, and manage tournaments. Managers and venue workers get
> dedicated dashboards, and an AI assistant handles natural-language
> booking and personalized recommendations.

---

## ✨ Features

### 🎮 For Players

- 🔍 **Discover venues** — browse sports fields near you on an interactive map
- 📅 **Real-time booking** — pick a time slot and reserve instantly
- 👥 **Create & join matches** — find teammates or opponents
- 🏆 **Tournaments** — browse, join, and follow tournament brackets
- 💬 **Instant chat** — talk with teammates and venue workers in real time
- 💳 **In-app payments** — secure checkout powered by Stripe
- ⭐ **Ratings & reviews** — rate venues and players after each game
- 🤖 **AI assistant** — ask in natural language ("book a football field near me tomorrow at 6pm") and get guided booking + recommendations

### 🏢 For Managers

- 📊 **Dashboard** — overview of bookings, revenue, and occupancy
- 🏟️ **Venue management** — create/edit courts, pricing, schedules
- 👷 **Worker management** — assign staff to venues
- 📆 **Day plans & week agendas** — organize time slots per court
- 💰 **Bookings & payments** — track reservations and payouts
- 🏆 **Tournament organizer** — create and run tournaments
- 📢 **Announcements** — broadcast updates to players

### 👷 For Workers

- 📋 **Assigned venues** — see only the courts you manage
- 📅 **Reservations queue** — approve, check in, or flag bookings
- 💬 **Manager & player chat** — coordinate in real time
- 📆 **Upcoming shifts** — day plan view

### 🛡️ For Admins

- 👥 **User management** — approve managers and workers
- 💳 **Payment oversight** — review transactions and disputes
- 📊 **Platform analytics**

---

## 🛠️ Tech Stack

| Layer              | Technology                                              |
|--------------------|---------------------------------------------------------|
| **Mobile app**     | Flutter (Dart) · Material 3                             |
| **Backend**        | Strapi 5 (Node.js) · REST API                           |
| **Database**       | MySQL 8                                                 |
| **Authentication** | Strapi users-permissions + Firebase Auth                |
| **Real-time chat** | Firebase Cloud Firestore                                |
| **Notifications**  | Firebase Cloud Messaging (FCM)                          |
| **Payments**       | Stripe (backend + Flutter SDK)                          |
| **Maps**           | Mapbox (primary) + flutter_map/OpenStreetMap (fallback) |
| **Geolocation**    | `geolocator` + `permission_handler`                     |
| **AI Assistant**   | LLM (Llama and others) via OpenRouter                   |
| **Email**          | Nodemailer (password reset flows)                       |

---

## 🏗️ Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER MOBILE APP                      │
│  Player · Manager · Worker · Admin (role-based navigation)  │
│       Provider state mgmt · Firebase SDK · Stripe SDK       │
└────────────┬───────────────────────────────┬────────────────┘
             │ REST (HTTPS)                  │ Firestore SDK
             ▼                               ▼
┌───────────────────────────┐   ┌───────────────────────────┐
│      STRAPI BACKEND       │   │         FIREBASE          │
│  - /api/auth              │   │  - Firestore (chat)       │
│  - /api/venue, court      │   │  - Auth (identity)        │
│  - /api/reservation       │   │  - Cloud Messaging (push) │
│  - /api/payment (Stripe)  │   └───────────────────────────┘
│  - /api/ai-agent          │
│  - /api/manager, worker   │
│  - /api/announcement      │
│  - role-based policies    │
└────────────┬──────────────┘
             │
             ▼
        ┌─────────┐
        │  MySQL  │
        └─────────┘
```

---

## 📁 Project Structure

```text
sporta/
├── Backend/                      # Strapi 5 API
│   ├── src/
│   │   ├── api/                  # Business endpoints
│   │   │   ├── admin/            # Platform administration
│   │   │   ├── ai-agent/         # LLM-powered assistant
│   │   │   ├── ai-conversation/  # Chat history with AI
│   │   │   ├── announcement/     # Broadcast messages
│   │   │   ├── auth/             # Custom auth flows
│   │   │   ├── court/            # Individual courts
│   │   │   ├── day-plan/         # Daily schedules
│   │   │   ├── join-request/     # Match join requests
│   │   │   ├── manager/          # Manager profiles
│   │   │   ├── message/          # Chat messages
│   │   │   ├── payment/          # Stripe integration
│   │   │   ├── player/           # Player profiles
│   │   │   ├── rating/           # Reviews & ratings
│   │   │   ├── reservation/      # Booking engine
│   │   │   ├── time-slot/        # Availability
│   │   │   ├── venue/            # Sports venues
│   │   │   ├── week-agenda/      # Weekly overview
│   │   │   └── worker/           # Worker profiles
│   │   ├── extensions/           # Strapi plugins
│   │   ├── firebase/             # FCM integration
│   │   ├── policies/             # Role-based access
│   │   │   ├── isAdmin.js
│   │   │   ├── isManager.js
│   │   │   ├── isPlayer.js
│   │   │   └── isWorker.js
│   │   └── utils/                # Booking + email helpers
│   └── package.json
│
├── Frontend/                     # Flutter app
│   ├── lib/
│   │   ├── Core/                 # Constants, theme, config
│   │   ├── Models/               # Data models
│   │   ├── Services/             # API + Firebase wrappers
│   │   │   ├── admin_auth_service.dart
│   │   │   ├── ai_chat_service.dart
│   │   │   ├── chat_service.dart
│   │   │   ├── court_service.dart
│   │   │   ├── location_service.dart
│   │   │   ├── payment_service.dart
│   │   │   ├── reservation_service.dart
│   │   │   └── ...               # and more
│   │   ├── Views/                # Screens (by role)
│   │   │   ├── Admin/
│   │   │   ├── Auth/
│   │   │   ├── Manager/
│   │   │   ├── Player/
│   │   │   ├── Worker/
│   │   │   └── SplashOnboarding/
│   │   └── Widgets/              # Reusable UI
│   └── pubspec.yaml
│
├── .gitignore
├── README.md
└── package.json
```

---

## 🚀 Getting Started

### Prerequisites

| Tool               | Version                |
|--------------------|------------------------|
| Node.js            | `>=20.0.0 <=24.x.x`    |
| npm                | `>=6.0.0`              |
| Flutter SDK        | `^3.10.8`              |
| MySQL              | 8.x                    |
| Firebase account   | with a project set up  |
| Stripe account     | (test keys are fine)   |
| OpenRouter account | (free tier works)      |

---

### 1. Clone the repository

```bash
git clone https://github.com/MedDhiaHasni/MySportaPorject.git
cd MySportaPorject
```

### 2. Set up the Backend (Strapi)

```bash
cd Backend
npm install
```

Create `Backend/.env` from the template:

```bash
cp .env.example .env
```

Then fill in the real values:

```dotenv
HOST=0.0.0.0
PORT=1337

# Strapi secrets — generate random ones with:
#   node -e "console.log(require('crypto').randomBytes(16).toString('base64'))"
APP_KEYS="key1,key2,key3,key4"
API_TOKEN_SALT=your_random_salt
ADMIN_JWT_SECRET=your_random_secret
TRANSFER_TOKEN_SALT=your_random_salt
JWT_SECRET=your_random_secret
ENCRYPTION_KEY=your_random_key

# Database
DATABASE_CLIENT=mysql
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_NAME=sporta
DATABASE_USERNAME=root
DATABASE_PASSWORD=your_password

# Firebase Admin SDK
FIREBASE_SERVICE_ACCOUNT_JSON=path/to/service-account.json

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# AI Assistant
OPENROUTER_API_KEY=sk-or-v1-...
OPENROUTER_MODEL=openrouter/free
```

> 💡 `openrouter/free` automatically routes to an available free model. Free
> models come and go, so this avoids breaking when a specific one is retired.
> Browse the current catalog at [openrouter.ai/models?max_price=0](https://openrouter.ai/models?max_price=0).

Create the database:

```bash
mysql -u root -p -e "CREATE DATABASE sporta CHARACTER SET utf8mb4;"
```

Start Strapi in dev mode:

```bash
npm run develop
```

The Strapi admin panel will be available at http://localhost:1337/admin.
Create your first admin user, then configure roles and permissions under
**Settings → Users & Permissions**.

### 3. Set up the Frontend (Flutter)

```bash
cd ../Frontend
flutter pub get
```

**Firebase setup** — you need two files:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Generate these from your Firebase project console and place them at the
paths above (they are gitignored — never commit them).

**API base URL** — edit `lib/Core/Constants/api_constants.dart` and point it
to your backend:

```dart
const String kApiBaseUrl = "http://10.0.2.2:1337"; // Android emulator
// or
const String kApiBaseUrl = "http://localhost:1337"; // iOS / desktop
```

Run the app:

```bash
flutter run
```

---

## 🔐 Security Notes

- All secrets live in `Backend/.env` — never committed.
- `.env.example` is committed as a template with placeholder values.
- Firebase config files (`google-services.json`, `GoogleService-Info.plist`) are gitignored.
- Role-based access control is enforced by Strapi policies (`isAdmin`, `isManager`, `isPlayer`, `isWorker`) on every protected route.
- Payment intents are created server-side (Stripe) — the client never sees the secret key.

---

## 🗺️ Roadmap

- [x] Strapi 5 backend with 18 domain APIs
- [x] MySQL persistence
- [x] Firebase Auth + Firestore chat + FCM notifications
- [x] Role-based Flutter UI (Player / Manager / Worker / Admin)
- [x] Stripe in-app payments
- [x] Mapbox integration with flutter_map fallback
- [x] Geolocation-based venue discovery
- [x] AI assistant via OpenRouter
- [ ] Backend deployment (Docker + VPS / cloud)
- [ ] Play Store & App Store release
- [ ] Push notification scheduling for match reminders
- [ ] Advanced analytics dashboard for managers

---

## 📸 Screenshots

> Coming soon — screenshots of the Player, Manager, Worker, and Admin
> interfaces will be added here.

---

## 🤝 Contributing

This project was built as an end-of-studies project (PFE) at FST El Manar.
Issues and suggestions are welcome.

---

## 👤 Author

**Med Dhia Hasni**
Computer Science Graduate — FST El Manar
Full-Stack Developer · Flutter · Node.js · Strapi
[GitHub](https://github.com/MedDhiaHasni)
