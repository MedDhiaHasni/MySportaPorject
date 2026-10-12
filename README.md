# Sporta: Smart Sports Field Reservation Platform

Sporta is a full-stack mobile application for booking sports fields in real time. Players discover and reserve venues, join matches, create teams, chat instantly, and take part in tournaments. Managers and venue workers have dedicated dashboards, and an AI assistant handles natural-language booking and personalized recommendations.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Configuration Reference](#configuration-reference)
- [Security](#security)
- [Roadmap](#roadmap)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [Author](#author)

---

## Features

### Players

- **Venue discovery:** browse sports fields near you on an interactive map.
- **Real-time booking:** pick a time slot and reserve instantly.
- **Matches:** create and join matches to find teammates or opponents.
- **Tournaments:** browse, join, and follow tournament brackets.
- **Instant chat:** talk with teammates and venue workers in real time.
- **In-app payments:** secure checkout powered by Stripe.
- **Ratings and reviews:** rate venues and players after each game.
- **AI assistant:** make requests in natural language (for example, "book a football field near me tomorrow at 6pm") and receive guided booking and recommendations.

### Managers

- **Dashboard:** overview of bookings, revenue, and occupancy.
- **Venue management:** create and edit courts, pricing, and schedules.
- **Worker management:** assign staff to venues.
- **Day plans and week agendas:** organize time slots per court.
- **Bookings and payments:** track reservations and payouts.
- **Tournament organizer:** create and run tournaments.
- **Announcements:** broadcast updates to players.

### Workers

- **Assigned venues:** see only the courts you manage.
- **Reservations queue:** approve, check in, or flag bookings.
- **Chat:** coordinate with managers and players in real time.
- **Upcoming shifts:** day plan view.

### Administrators

- **User management:** approve managers and workers.
- **Payment oversight:** review transactions and disputes.
- **Platform analytics:** monitor activity across the platform.

---

## Tech Stack

| Layer              | Technology                                              |
|--------------------|---------------------------------------------------------|
| Mobile app         | Flutter (Dart), Material 3                              |
| Backend            | Strapi 5 (Node.js), REST API                            |
| Database           | MySQL 8                                                 |
| Authentication     | Strapi users-permissions and Firebase Auth              |
| Real-time chat     | Firebase Cloud Firestore                                |
| Notifications      | Firebase Cloud Messaging (FCM)                          |
| Payments           | Stripe (backend and Flutter SDK)                        |
| Maps               | Mapbox (primary), flutter_map / OpenStreetMap (fallback)|
| Geolocation        | `geolocator` and `permission_handler`                   |
| AI assistant       | LLM (Llama and others) via OpenRouter                   |
| Email              | Nodemailer (password reset flows)                       |

---

## Architecture

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

## Project Structure

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
│   │   │   ├── rating/           # Reviews and ratings
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
│   │   └── utils/                # Booking and email helpers
│   └── package.json
│
├── Frontend/                     # Flutter app
│   ├── lib/
│   │   ├── Core/                 # Constants, theme, config
│   │   ├── Models/               # Data models
│   │   ├── Services/             # API and Firebase wrappers
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
│   │   └── Widgets/              # Reusable UI components
│   └── pubspec.yaml
│
├── .gitignore
├── README.md
└── package.json
```

---

## Getting Started

### Prerequisites

| Tool               | Version                |
|--------------------|------------------------|
| Node.js            | `>=20.0.0 <=24.x.x`    |
| npm                | `>=6.0.0`              |
| Flutter SDK        | `^3.10.8`              |
| MySQL              | 8.x                    |
| Firebase account   | with a project set up  |
| Stripe account     | test keys are sufficient |
| OpenRouter account | free tier is sufficient |

### 1. Clone the repository

```bash
git clone https://github.com/MedDhiaHasni/MySportaPorject.git
cd MySportaPorject
```

### 2. Set up the backend (Strapi)

```bash
cd Backend
npm install
```

Create `Backend/.env` from the template:

```bash
cp .env.example .env
```

Fill in the real values (see the [Configuration Reference](#configuration-reference)):

```dotenv
HOST=0.0.0.0
PORT=1337

# Strapi secrets. Generate random values with:
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

# AI assistant
OPENROUTER_API_KEY=sk-or-v1-...
OPENROUTER_MODEL=openrouter/free
```

Create the database:

```bash
mysql -u root -p -e "CREATE DATABASE sporta CHARACTER SET utf8mb4;"
```

Start Strapi in development mode:

```bash
npm run develop
```

The Strapi admin panel is available at `http://localhost:1337/admin`. Create the first admin user, then configure roles and permissions under **Settings > Users & Permissions**.

### 3. Set up the frontend (Flutter)

```bash
cd ../Frontend
flutter pub get
```

**Firebase setup.** Two configuration files are required:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Generate them from your Firebase project console and place them at the paths above. Both files are gitignored and must never be committed.

**API base URL.** Edit `lib/Core/Constants/api_constants.dart` and point it to your backend:

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

## Configuration Reference

| Variable                         | Description                                         |
|----------------------------------|-----------------------------------------------------|
| `HOST`, `PORT`                   | Network binding for the Strapi server               |
| `APP_KEYS`                       | Comma-separated session signing keys                |
| `API_TOKEN_SALT`                 | Salt for API tokens                                 |
| `ADMIN_JWT_SECRET`               | Secret for admin panel authentication               |
| `TRANSFER_TOKEN_SALT`            | Salt for data transfer tokens                       |
| `JWT_SECRET`                     | Secret for users-permissions tokens                 |
| `ENCRYPTION_KEY`                 | Key for encrypting sensitive fields                 |
| `DATABASE_*`                     | MySQL connection settings                           |
| `FIREBASE_SERVICE_ACCOUNT_JSON`  | Path to the Firebase Admin SDK service account file |
| `STRIPE_SECRET_KEY`              | Stripe secret key (server-side only)                |
| `STRIPE_WEBHOOK_SECRET`          | Stripe webhook signing secret                       |
| `OPENROUTER_API_KEY`             | OpenRouter API key for the AI assistant             |
| `OPENROUTER_MODEL`               | Model identifier used by the AI assistant           |

**Note on the AI model.** `openrouter/free` routes each request to an available free model on OpenRouter. Free models are retired regularly, so a router avoids breakage when a specific model disappears. The current catalog is available at [openrouter.ai/models?max_price=0](https://openrouter.ai/models?max_price=0).

---

## Security

- All secrets are stored in `Backend/.env` and are never committed.
- `.env.example` is committed as a template with placeholder values.
- Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`) are gitignored.
- Role-based access control is enforced by Strapi policies (`isAdmin`, `isManager`, `isPlayer`, `isWorker`) on every protected route.
- Stripe payment intents are created server-side, so the client never has access to the secret key.

---

## Roadmap

**Completed**

- [x] Strapi 5 backend with 18 domain APIs
- [x] MySQL persistence
- [x] Firebase Auth, Firestore chat, and FCM notifications
- [x] Role-based Flutter UI (Player, Manager, Worker, Admin)
- [x] Stripe in-app payments
- [x] Mapbox integration with flutter_map fallback
- [x] Geolocation-based venue discovery
- [x] AI assistant via OpenRouter

**Planned**

- [ ] Backend deployment (Docker, VPS or cloud)
- [ ] Play Store and App Store release
- [ ] Push notification scheduling for match reminders
- [ ] Advanced analytics dashboard for managers

---

## Screenshots

Screenshots of the Player, Manager, Worker, and Admin interfaces will be added here.

---

## Contributing

This project was built as an end-of-studies project (PFE) at FST El Manar. Issues and suggestions are welcome.

---

## Author

**Med Dhia Hasni**
Computer Science Graduate, FST El Manar
Full-Stack Developer (Flutter, Node.js, Strapi)

[GitHub](https://github.com/MedDhiaHasni)
