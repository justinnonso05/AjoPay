# PayAjo

**PayAjo** digitizes and secures the traditional African rotational savings model (Ajo / Esusu / Susu) using modern fintech infrastructure. Built as our official submission for the **API Conference X Monnify Hackathon**, PayAjo removes the friction, mistrust, and manual accounting of traditional group savings.

By deeply integrating with Monnify's robust payment APIs, we provide every user with a personal wallet, every group with a unified pool ledger, and completely automate the financial lifecycle of community savings.

## 🏆 Key Features

- **Automated Contribution Tracking:** Say goodbye to chasing members or manual record-keeping. Every contribution is logged and matched automatically when the transfer lands.
- **Group Pool Ledgers:** Group funds are securely aggregated in a dedicated ledger, ensuring transparent and real-time visibility into the group's financial health.
- **Personal Wallets (Powered by Monnify):** Users receive dedicated virtual accounts to easily fund their personal wallets, allowing them to deposit once and pay contributions instantly.
- **Automated Payouts & Auto-Debits:** Our background scheduler evaluates group health and automatically debits members and processes payouts to the assigned cycle member.
- **Ultimate Flexibility (Cycle Swaps & Delegation):** Need funds early? Members can securely request to swap payout cycles with another member. Want to settle a debt? Members can delegate their payout to another person’s wallet.
- **Real-Time Communication:** A built-in WebSocket-powered group chat ensures your community stays connected, complete with system messages that automatically broadcast important financial events.
- **Identity Verification:** Integrated BVN checks ensure that every member is identity-verified before joining a trusted savings circle.
- **Instant Push Notifications:** Firebase Cloud Messaging (FCM) keeps users updated on successful contributions, cycle approvals, chat messages, and impending auto-debits.
- **AI-Powered Localization (Gemini Integration):** We integrated Google's Gemini AI to dynamically translate complex financial terms and app content into Local Nigerian Pidgin, making the platform fully accessible to grassroots and non-technical users.

## 🏗️ Architecture & Tech Stack

PayAjo is a full-stack monorepo consisting of three main environments:

1. **Backend (Python / FastAPI):**
   - High-performance asynchronous REST API and WebSockets.
   - **Database:** PostgreSQL with SQLAlchemy (Async) + Alembic for migrations.
   - **Job Scheduling:** APScheduler for running periodic background jobs (Payouts, Auto-Debits, Reminders).
   - **External APIs:** Monnify (Wallets, Webhooks, Transfers), Firebase Admin (Push Notifications), Brevo (Transactional Emails), Cloudinary (Chat Image Hosting).

2. **Mobile App (Flutter / Dart):**
   - Cross-platform (iOS and Android) mobile client.
   - Clean architecture with Riverpod for robust state management.
   - Firebase Cloud Messaging integration for foreground/background push notifications.
   - Secure storage for JWT access and refresh tokens.

3. **Web Platform (Next.js / React 19):**
   - A fully functional, highly-responsive web application that serves as the alternative client to the mobile app.
   - Built entirely with Tailwind CSS (v4) for styling.

## ⚙️ Monnify API Integration

PayAjo heavily utilizes the Monnify API to handle all money movements:
- **Virtual Accounts:** We generate dedicated virtual accounts for users so they can fund their internal PayAjo wallets.
- **Webhook Processing:** We listen for `SUCCESSFUL_TRANSACTION` webhooks to instantly credit user wallets or group ledgers and trigger realtime notifications.
- **Disbursements/Transfers:** When a payout cycle completes, we utilize Monnify's transfer API to disburse funds securely to the assigned member's bank account or internal wallet.

## 🚀 Getting Started

### Prerequisites
- Python 3.12+
- Flutter SDK (latest)
- Node.js 20+
- PostgreSQL
- Monnify Developer Account Keys
- Firebase Admin SDK JSON
- Brevo & Cloudinary API Keys

### 1. Setting up the Backend
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Create a .env file based on the environment variables required (DB, Monnify, etc.)
# Run database migrations
alembic upgrade head

# Start the FastAPI server
fastapi dev app/main.py
```

### 2. Setting up the Mobile App
```bash
cd mobile
flutter pub get

# Generate Riverpod/Freezed/Retrofit files
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app on a connected device or emulator
flutter run
```

### 3. Setting up the Web Platform
```bash
cd frontend
npm install

# Start the Next.js development server
npm run dev
```

## 🛡️ Security
- All sensitive operations (like delegating or swapping payouts) require a secondary **Transaction PIN**.
- Robust PIN rate-limiting prevents brute force attacks.
- JWT-based authentication with short-lived access tokens and secure refresh token rotation.
- Webhook signatures are cryptographically verified using HMAC SHA-512 to ensure authenticity from Monnify.
