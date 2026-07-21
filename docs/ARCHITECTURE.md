# PayAjo — Architecture Diagrams

---

## 1. System Architecture Overview

High-level view of the entire PayAjo platform showing how the Mobile App, Web App, Backend API, Database, and External Services interconnect.

```mermaid
graph TB
    subgraph Clients["Client Applications"]
        Mobile["📱 Mobile App<br/>(Flutter — Android & iOS)"]
        Web["🌐 Web App<br/>(Next.js — Vercel)"]
    end

    subgraph Backend["Backend Server (FastAPI)"]
        API["🔌 REST API<br/>FastAPI + Uvicorn"]
        WS["📡 WebSocket<br/>Real-time Chat"]
        Scheduler["⏰ APScheduler<br/>Automated Payouts"]
    end

    subgraph Database["Data Layer"]
        PG["🗄️ PostgreSQL<br/>Primary Database"]
        Alembic["📦 Alembic<br/>Schema Migrations"]
    end

    subgraph ExternalServices["External Services"]
        Monnify["🏦 Monnify API<br/>Virtual Accounts & Payouts"]
        FCM["🔔 Firebase Cloud Messaging<br/>Push Notifications"]
        Cloudinary["🖼️ Cloudinary<br/>Image Uploads"]
        SMTP["📧 SMTP<br/>Email (OTP & Receipts)"]
    end

    Mobile -->|HTTPS REST + WebSocket| API
    Web -->|HTTPS REST + WebSocket| API
    Mobile -->|FCM Token Sync| FCM
    API --> PG
    Alembic -->|Migrations| PG
    API --> WS
    Scheduler -->|Cron: Process Payouts| PG
    API -->|Create Virtual Accounts<br/>Process Payouts| Monnify
    API -->|Push Notifications| FCM
    API -->|Upload Chat Images| Cloudinary
    API -->|Send OTP & Receipts| SMTP
    Monnify -->|Webhook: Payment Received| API

    style Clients fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style Backend fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style Database fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style ExternalServices fill:#fce4ec,stroke:#c62828,stroke-width:2px
```

---

## 2. Backend Modular Architecture

The backend follows a modular domain-driven design. Each domain module contains its own `models.py`, `schemas.py`, `service.py`, and `router.py`.

```mermaid
graph LR
    subgraph Core["⚙️ Core Layer"]
        Config["config.py<br/>Environment & Settings"]
        DB["database.py<br/>SQLAlchemy Engine"]
        Security["security.py<br/>JWT & Password Hashing"]
        PinLimiter["pin_limiter.py<br/>Brute-force Protection"]
        SchedulerCore["scheduler.py<br/>APScheduler Setup"]
        WSManager["websocket.py<br/>Connection Manager"]
    end

    subgraph Modules["📦 Domain Modules"]
        Auth["🔐 Auth<br/>Login, Register, OTP,<br/>Password Reset"]
        User["👤 User<br/>Profile, KYC, BVN,<br/>PIN, FCM Token"]
        Group["👥 Group<br/>Create, Join, Invite,<br/>Start, Edit"]
        Membership["🤝 Membership<br/>Approve, Remove,<br/>Pending Members"]
        Cycle["🔄 Cycle<br/>Rotations, Swaps,<br/>Delegations"]
        Transaction["💰 Transaction<br/>Contributions, Payouts,<br/>Wallet History"]
        Chat["💬 Chat<br/>WebSocket Messages,<br/>Image Uploads"]
        Notification["🔔 Notification<br/>In-app Alerts,<br/>FCM Push Triggers"]
        Webhook["🪝 Webhook<br/>Monnify Payment<br/>Confirmations"]
    end

    subgraph Services["🔧 External Service Layer"]
        MonnifyService["monnify.py<br/>Virtual Accounts & Disbursement"]
        PushService["push.py<br/>Firebase Admin SDK"]
        EmailService["email.py<br/>SMTP + HTML Templates"]
        CloudinaryService["cloudinary.py<br/>Image CDN"]
        RiskService["risk.py<br/>Risk Scoring"]
        AIService["ai.py<br/>AI-Powered Features"]
    end

    Core --> Modules
    Modules --> Services

    style Core fill:#e8eaf6,stroke:#283593,stroke-width:2px
    style Modules fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style Services fill:#fff3e0,stroke:#e65100,stroke-width:2px
```

---

## 3. Mobile App Architecture (Flutter)

The Flutter mobile app follows a feature-first architecture with Riverpod for state management.

```mermaid
graph TB
    subgraph Presentation["🖥️ Presentation Layer"]
        Splash["Splash Screen"]
        Onboarding["Onboarding"]
        AuthScreens["Auth Screens<br/>Login, Signup,<br/>BVN Verify, PIN Setup"]
        HomeTab["Home Tab"]
        GroupScreens["Group Screens<br/>Details, Contribute,<br/>Chat, Direct Pay"]
        WalletTab["Wallet Tab<br/>Balance, History,<br/>Payout Bank"]
        ProfileTab["Profile Tab"]
        NotificationsScreen["Notifications"]
    end

    subgraph State["📊 State Management (Riverpod)"]
        UserProfile["UserProfileController<br/>Current User State"]
        GroupProviders["Group Providers<br/>List, Details, Members"]
        WalletController["WalletController<br/>Balance & Transactions"]
        NotifController["Notification Provider<br/>Unread Count & List"]
    end

    subgraph Data["📡 Data Layer"]
        ApiClient["ApiClient<br/>HTTP + JWT Auth"]
        SecureStorage["SecureStorage<br/>Token Persistence"]
        NotificationService["NotificationService<br/>FCM + Permission"]
        UserRepo["UserRepository"]
        GroupRepo["GroupRepository"]
        WalletRepo["WalletRepository"]
    end

    subgraph External["🌐 External"]
        BackendAPI["FastAPI Backend"]
        Firebase["Firebase"]
    end

    Presentation --> State
    State --> Data
    Data --> External
    ApiClient -->|REST API Calls| BackendAPI
    NotificationService -->|FCM Token| Firebase

    style Presentation fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style State fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style Data fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style External fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px
```

---

## 4. Contribution & Payout Data Flow

Shows the complete lifecycle of a savings group contribution round — from payment to automated payout.

```mermaid
sequenceDiagram
    participant U as 👤 Group Member
    participant App as 📱 Mobile / Web App
    participant API as 🔌 FastAPI Backend
    participant DB as 🗄️ PostgreSQL
    participant Mon as 🏦 Monnify
    participant FCM as 🔔 Firebase FCM
    participant Sched as ⏰ Scheduler

    Note over U, Sched: Phase 1 — Member Contributes
    U->>App: Tap "Contribute" + Enter PIN
    App->>API: POST /groups/{id}/contribute<br/>{amount, pin}
    API->>API: Verify PIN & Check Balance
    API->>DB: Debit Wallet, Credit Pool
    API->>DB: Record Transaction
    API->>FCM: Push "Contribution Received"
    API-->>App: 200 OK {transaction}
    App-->>U: ✅ Success Screen

    Note over U, Sched: Phase 2 — Auto-Debit (Optional)
    Sched->>DB: Check auto-debit schedules
    Sched->>DB: Debit wallet for unpaid members
    Sched->>FCM: Push "Auto-debit processed"

    Note over U, Sched: Phase 3 — Automated Payout
    Sched->>DB: Check if all members paid
    Sched->>DB: Identify current recipient
    Sched->>Mon: POST /disbursements<br/>{recipient_bank, amount}
    Mon-->>Sched: Disbursement Confirmed
    Sched->>DB: Record payout, advance cycle
    Sched->>FCM: Push "Payout sent to [Member]!"
```

---

## 5. Database Schema (Key Entities)

```mermaid
erDiagram
    User {
        uuid id PK
        string email UK
        string username UK
        string phone
        string first_name
        string last_name
        string hashed_password
        string hashed_pin
        string bvn_status
        decimal wallet_balance
        string fcm_token
        string payout_bank_code
        string payout_account_number
        int risk_score
    }

    Group {
        uuid id PK
        uuid admin_user_id FK
        string name
        decimal contribution_amount
        string cycle_frequency
        string status
        int current_cycle_number
        string invite_code UK
        int member_cap
        decimal pool_balance
        datetime next_payout_date
    }

    Membership {
        uuid id PK
        uuid user_id FK
        uuid group_id FK
        string status
        bool is_admin
        bool auto_debit_enabled
        int auto_debit_days_before
        int payout_position
    }

    Transaction {
        uuid id PK
        uuid user_id FK
        uuid group_id FK
        string type
        decimal amount
        int cycle_number
        string status
        string reference
    }

    Notification {
        uuid id PK
        uuid user_id FK
        string title
        string body
        string type
        bool is_read
    }

    ChatMessage {
        uuid id PK
        uuid group_id FK
        uuid sender_id FK
        string content
        string image_url
    }

    RotationEntry {
        uuid id PK
        uuid group_id FK
        uuid user_id FK
        int cycle_number
        string status
    }

    User ||--o{ Membership : "joins"
    Group ||--o{ Membership : "has"
    User ||--o{ Transaction : "makes"
    Group ||--o{ Transaction : "receives"
    User ||--o{ Notification : "receives"
    Group ||--o{ ChatMessage : "contains"
    User ||--o{ ChatMessage : "sends"
    Group ||--o{ RotationEntry : "schedules"
    User ||--o{ RotationEntry : "assigned"
    Group }o--|| User : "admin"
```

---

## 6. Push Notification Flow

```mermaid
graph TB
    subgraph MobileApp["📱 Mobile App (Flutter)"]
        Init["App Launch<br/>Firebase.initializeApp()"]
        Perm["Request Notification<br/>Permission"]
        Token["Get FCM Device Token"]
        Sync["POST /users/me/fcm-token<br/>Sync token with backend"]
        FG["Foreground Listener<br/>Show in-app banner"]
        BG["Background Handler<br/>System notification tray"]
    end

    subgraph Backend["🔌 Backend (FastAPI)"]
        SaveToken["Save fcm_token<br/>to User table"]
        Event["SQLAlchemy after_insert<br/>on Notification table"]
        PushService2["push.py<br/>firebase_admin.messaging"]
    end

    subgraph FCMCloud["☁️ Firebase Cloud Messaging"]
        FCMServer["FCM Server<br/>Routes to device"]
    end

    subgraph Phone["📱 User's Phone"]
        Tray["Notification Tray"]
        AppOpen["App Opens<br/>on Tap"]
    end

    Init --> Perm --> Token --> Sync
    Sync -->|HTTPS| SaveToken
    Event -->|Trigger| PushService2
    PushService2 -->|Send to device token| FCMServer
    FCMServer --> FG
    FCMServer --> BG
    FCMServer --> Tray
    Tray -->|User Taps| AppOpen

    style MobileApp fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style Backend fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style FCMCloud fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style Phone fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px
```

---

## 7. Deployment Architecture

```mermaid
graph TB
    subgraph Users["👥 End Users"]
        Android["📱 Android<br/>APK Download"]
        iOS["📱 iOS<br/>Xcode / TestFlight"]
        Browser["🌐 Web Browser"]
    end

    subgraph Hosting["☁️ Hosting & Deployment"]
        Vercel["▲ Vercel<br/>Next.js Frontend<br/>payajo.vercel.app"]
        Render["🚀 Backend Host<br/>FastAPI + Uvicorn"]
        PGHost["🐘 PostgreSQL<br/>Managed Database"]
    end

    subgraph ThirdParty["🔧 Third-Party Services"]
        GH["GitHub<br/>Source Control & CI"]
        Firebase2["Firebase<br/>FCM + Analytics"]
        Monnify2["Monnify<br/>Payments"]
        Cloudinary2["Cloudinary<br/>Image CDN"]
    end

    Android -->|HTTPS| Render
    iOS -->|HTTPS| Render
    Browser -->|HTTPS| Vercel
    Vercel -->|API Calls| Render
    Render --> PGHost
    Render --> Firebase2
    Render --> Monnify2
    Render --> Cloudinary2
    GH -->|Auto Deploy| Vercel
    GH -->|Auto Deploy| Render

    style Users fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style Hosting fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style ThirdParty fill:#fff3e0,stroke:#e65100,stroke-width:2px
```

---

## Tech Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile** | Flutter (Dart) | Cross-platform Android & iOS app |
| **Web Frontend** | Next.js 16 + TailwindCSS | Landing page + Web dashboard |
| **Backend API** | FastAPI (Python) | REST API + WebSocket |
| **Database** | PostgreSQL + SQLAlchemy | Relational data storage |
| **Migrations** | Alembic | Database schema versioning |
| **State Mgmt** | Riverpod | Flutter state management |
| **Auth** | JWT (access + refresh tokens) | Stateless authentication |
| **Payments** | Monnify | Virtual accounts & disbursement |
| **Push Notifications** | Firebase Cloud Messaging | Real-time device notifications |
| **Image Storage** | Cloudinary | Chat image uploads & CDN |
| **Email** | SMTP + HTML Templates | OTP verification & receipts |
| **Scheduling** | APScheduler | Automated payouts & auto-debit |
| **Deployment** | Vercel + Render | Frontend & Backend hosting |
| **Source Control** | GitHub | Version control & CI/CD |
