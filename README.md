# PayAjo

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Next.js](https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white)](https://nextjs.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org)
[![Monnify](https://img.shields.io/badge/Monnify-003366?style=for-the-badge&logo=bank&logoColor=white)](https://monnify.com)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Google_Gemini-8E75B2?style=for-the-badge&logo=googlegemini&logoColor=white)](https://deepmind.google/technologies/gemini/)

**PayAjo** digitizes and secures the traditional African rotational savings model (Ajo / Esusu / Susu) using modern fintech infrastructure. Built as our official submission for the **API Conference X Monnify Hackathon**, PayAjo removes the friction, mistrust, and manual accounting of traditional group savings.

By deeply integrating with Monnify's robust payment APIs, we provide every user with a personal wallet, every group with a unified pool ledger, and completely automate the financial lifecycle of community savings.

---

## 🔗 Quick Links & Demo

- 🌐 **Web App & Landing Page:** [https://payajo.vercel.app](https://payajo.vercel.app/)
- 📱 **Android Direct APK Download:** [Download PayAjo.apk](https://drive.google.com/uc?export=download&id=1wdCYF5KA6miPZy4_5QyoTpE8z3rmYNYH)
- 🎥 **Video Demo (YouTube):** [Watch Video Demo](https://youtu.be/0F9QWjEhHCQ)
- 📑 **Slide Deck / Pitch Deck:** [View Presentation on Google Slides](https://docs.google.com/presentation/d/1kgaMrjyplNzRpSNn1S2cpq_Pr-YISq-IKOLf_JDk6CA/edit?usp=sharing)

---

## 🔄 User Flow

`Sign Up` ➔ `Complete Profile` ➔ `BVN Verification` ➔ `Virtual Wallet Created` ➔ `Create or Join Group` ➔ `Set Transaction PIN` ➔ `Start Saving & Rotating Payouts`

---

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
- **Seamless Cross-Platform Sync (Web & Mobile):** Works seamlessly across Web and Mobile apps — users can manage groups, chat, pay contributions, and track payouts on either platform with 100% real-time data synchronization.

---

## 📸 Application Screenshots

### Web Platform & Landing Page
![PayAjo Landing Page](docs/images/landing.png)

### Mobile Application (Flutter — iOS & Android)
| Home Screen | Group Details & Contributions |
| :---: | :---: |
| ![Home Screen](docs/images/home.png) | ![Group Details](docs/images/group%20details.png) |

| Realtime Group Chat | Personal Wallet & Funding |
| :---: | :---: |
| ![Group Chat](docs/images/group-chat.png) | ![Personal Wallet](docs/images/fund-wallet.png) |

| Onboarding & BVN Verification | Receive Payout & Notifications |
| :---: | :---: |
| ![Onboarding](docs/images/onboarding.png) | ![Receive Payout](docs/images/receive-payout.png) |

| Push Notification Alerts |
| :---: |
| ![Push Notifications](docs/images/image.png) |

---

## 🏗️ Architecture & Tech Stack

PayAjo is a full-stack monorepo consisting of three main environments:

1. **Backend (Python / FastAPI):**
   - High-performance asynchronous REST API and WebSockets.
   - **Database:** PostgreSQL with SQLAlchemy (Async) + Alembic for migrations.
   - **Job Scheduling:** APScheduler for running periodic background jobs (Payouts, Auto-Debits, Reminders).
   - **External APIs:** Monnify (Wallets, Webhooks, Transfers), Firebase Admin (Push Notifications), Brevo (Transactional Emails), Cloudinary (Chat Image Hosting).

2. **Mobile App (Flutter / Dart):**
   - Cross-platform (**Android and iOS**) mobile client.
   - Clean architecture with Riverpod for robust state management.
   - Firebase Cloud Messaging integration for foreground/background push notifications.
   - Secure storage for JWT access and refresh tokens.

3. **Web Platform (Next.js / React 19):**
   - A fully functional, highly-responsive web application that serves as the alternative client to the mobile app.
   - Built entirely with Tailwind CSS (v4) for styling.

---

## ⚙️ Monnify API Integration

PayAjo deeply integrates with Monnify's sandbox API suite to power all monetary flows:

- **Reserved Virtual Accounts (`/api/v2/bank-transfer/reserved-accounts`):** Automatically provisioned during user signup so every user has a dedicated bank account number to fund their personal PayAjo wallet via bank transfer.
- **Dynamic Virtual Accounts (`/api/v1/merchant/transactions/init-transaction` & `/init-payment`):** Generates single-use virtual accounts for instant, direct-to-group contributions.
- **Account Validation & Bank List (`/api/v1/disbursements/account/validate` & `/api/v1/banks`):** Real-time account name enquiry so members can verify their payout bank details before withdrawing.
- **Single Transfer Disbursements (`/api/v2/disbursements/single`):** Automatically disburses accumulated group pools directly into the scheduled beneficiary's bank account when a cycle completes.
- **Disbursement Authorization (`/api/v2/disbursements/single/validate-otp`):** Secure OTP verification for payout approvals.
- **Webhook Engine (`/api/v1/webhooks`):** Real-time listening for `SUCCESSFUL_TRANSACTION` webhooks to instantly record contributions, update group ledgers, and trigger FCM push notifications.

---

## 📚 API & Resources Documentation

- 📚 **Interactive ReDoc API Docs:** [https://payajo.fastapicloud.dev/redoc](https://payajo.fastapicloud.dev/redoc)
- 📮 **Monnify Postman Collection:** [View Postman Collection](https://documenter.getpostman.com/view/36406749/2sBY4PQ187)
- 🎨 **Figma UI/UX Designs:** [View Figma File](https://www.figma.com/design/Yd4hlLebZIca1GCQ9f5sqf/PayAjo-App-Listing-Images?node-id=0-1&t=MWKllJq6Sh8LhSNB-1)

---

## 🔑 Environment Variables

### 1. Backend (`backend/.env`)
```env
PROJECT_NAME="PayAjo Backend"
DATABASE_URL="postgresql+asyncpg://user:password@localhost:5432/ajopay"
SECRET_KEY="your-jwt-secret-key"
ALGORITHM="HS256"
ACCESS_TOKEN_EXPIRE_MINUTES=10080

# Monnify Sandbox Credentials
MONNIFY_API_KEY="your-monnify-api-key"
MONNIFY_SECRET_KEY="your-monnify-secret-key"
MONNIFY_BASE_URL="https://sandbox.monnify.com"
MONNIFY_CONTRACT_CODE="your-monnify-contract-code"
MONNIFY_WALLET_ACCOUNT="9999999999"

# Email & Services
BREVO_API_KEY="your-brevo-api-key"
EMAIL_FROM_ADDRESS="noreply@payajo.app"
EMAIL_FROM_NAME="PayAjo"
CLOUDINARY_URL="cloudinary://api_key:api_secret@cloud_name"
GEMINI_API_KEY="your-google-gemini-api-key"
```

### 2. Mobile App (`mobile/.env`)
```env
API_BASE_URL="https://payajo.fastapicloud.dev"
```

### 3. Web Platform (`frontend/.env.local`)
```env
NEXT_PUBLIC_API_BASE_URL="https://payajo.fastapicloud.dev"
```

---

## 🚀 Getting Started

### Prerequisites
- Python 3.12+
- Flutter SDK 3.29+ (Supports **Android & iOS**)
- Node.js 20+
- PostgreSQL

---

### 1. Setting up the Backend
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Run database migrations
alembic upgrade head

# Start the FastAPI server
fastapi dev app/main.py
```

---

### 2. Setting up the Mobile App (Supports Android & iOS)
```bash
cd mobile

# Install dependencies
flutter pub get

# Generate Riverpod / Freezed code bindings
flutter pub run build_runner build --delete-conflicting-outputs

# Check your environment & connected devices
flutter doctor

# Run the app on Android emulator, iOS simulator, or physical device
flutter run
```

---

### 3. Setting up the Web Platform
```bash
cd frontend

# Install Node dependencies
npm install

# Start the Next.js development server
npm run dev
```

---

## 🛡️ Security
- All sensitive operations (like delegating or swapping payouts) require a secondary **Transaction PIN**.
- Robust PIN rate-limiting prevents brute force attacks.
- JWT-based authentication with short-lived access tokens and secure refresh token rotation.
- Webhook signatures are cryptographically verified using HMAC SHA-512 to ensure authenticity from Monnify.

---

## 👥 Team & Contributors

- **Sultan** ([@devsultan06](https://github.com/devsultan06/)) — Frontend, Flutter Mobile App
- **Justin** ([@justinnonso05](https://github.com/justinnonso05)) — Backend, Infrastructure

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
