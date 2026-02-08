# Momentra - Technology Stack & Process Flowcharts

## Table of Contents
1. [Technology Stack Overview](#technology-stack-overview)
2. [Application Initialization Flow](#application-initialization-flow)
3. [Authentication Flow](#authentication-flow)
4. [Moments Management Flow](#moments-management-flow)
5. [Data Flow Architecture](#data-flow-architecture)
6. [State Management Flow](#state-management-flow)
7. [API Request Flow](#api-request-flow)
8. [Component Interaction Diagram](#component-interaction-diagram)

---

## Technology Stack Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        MOMENTRA APP                             │
│                    (Flutter/Dart Application)                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│   SUPABASE    │    │  REST API     │    │ LOCAL STORAGE │
│  (Auth & DB)  │    │  (Backend)    │    │ (SharedPrefs) │
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  Supabase     │    │  FastAPI/     │    │  Device       │
│  Cloud        │    │  Node.js      │    │  Storage      │
│  Services     │    │  Backend      │    │               │
└───────────────┘    └───────────────┘    └───────────────┘
```

### Technology Components Explained

#### **Frontend Layer**
- **Flutter Framework**: Cross-platform UI framework
- **Dart Language**: Programming language for Flutter
- **Riverpod**: State management library (dependency injection + reactive state)

#### **Authentication Layer**
- **Supabase Auth**: Handles user registration, login, JWT tokens
- **Supabase Database**: Stores user profiles (`profiles` table)
- **JWT Tokens**: Used for API authentication

#### **Backend API Layer**
- **REST API**: External backend service (FastAPI/Node.js)
- **Dio HTTP Client**: Makes API requests with interceptors
- **Bearer Token Auth**: JWT tokens in Authorization header

#### **Local Storage Layer**
- **SharedPreferences**: Key-value storage for app preferences
- **Token Storage**: Stores auth tokens locally
- **User Data Cache**: Caches user ID and preferences

---

## Application Initialization Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    APP STARTUP SEQUENCE                         │
└─────────────────────────────────────────────────────────────────┘

1. main() Function Called
   │
   ├─► WidgetsFlutterBinding.ensureInitialized()
   │   └─► Ensures Flutter widgets are ready
   │
   ├─► Supabase.initialize()
   │   ├─► URL: https://uzlctsulpzlvwvlkekgj.supabase.co
   │   ├─► Anon Key: sb_publishable_TNo02OZJnNUGYI0KoG1Aaw_KxEkyoCU
   │   └─► Creates SupabaseClient instance
   │
   ├─► currentUser() Check
   │   ├─► Checks Supabase.auth.currentUser
   │   ├─► If user exists → initialRoute = '/'
   │   └─► If no user → initialRoute = '/login'
   │
   └─► runApp(ProviderScope(...))
       ├─► ProviderScope: Wraps app with Riverpod providers
       ├─► MaterialApp: Sets up routing and theme
       └─► Initial Route: Navigates to home or login
```

### Detailed Explanation

**Step 1: Flutter Initialization**
- `WidgetsFlutterBinding.ensureInitialized()` ensures Flutter's widget system is ready before any async operations

**Step 2: Supabase Initialization**
- Connects to Supabase cloud service
- Sets up authentication client
- Configures API endpoints

**Step 3: Authentication Check**
- Checks if user session exists
- Determines initial route based on auth status
- If authenticated → Home screen
- If not authenticated → Login screen

**Step 4: App Launch**
- `ProviderScope` enables Riverpod state management throughout the app
- `MaterialApp` configures navigation and theming
- App starts with appropriate initial screen

---

## Authentication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FLOW                          │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │ Login Screen │
                    └──────┬───────┘
                           │
                           │ User enters credentials
                           ▼
                    ┌──────────────┐
                    │ AuthRepository│
                    │  .login()    │
                    └──────┬───────┘
                           │
                           │ Supabase Auth API Call
                           ▼
              ┌────────────────────────┐
              │  Supabase Auth Service │
              │  signInWithPassword()  │
              └───────────┬────────────┘
                          │
                          │ Validates credentials
                          │ Returns JWT token
                          ▼
              ┌────────────────────────┐
              │  Profile Lookup        │
              │  profiles table query  │
              └───────────┬────────────┘
                          │
                          │ Returns user profile
                          ▼
              ┌────────────────────────┐
              │  AppAuthResponse       │
              │  - User object         │
              │  - JWT token           │
              └───────────┬────────────┘
                          │
                          │ Stores session
                          ▼
              ┌────────────────────────┐
              │  Supabase Session      │
              │  - Access token        │
              │  - Refresh token       │
              │  - User metadata       │
              └───────────┬────────────┘
                          │
                          │ Navigate to home
                          ▼
                    ┌──────────────┐
                    │ Home Screen  │
                    └──────────────┘
```

### Registration Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    REGISTRATION FLOW                            │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │ Login Screen │
                    │ (Register)   │
                    └──────┬───────┘
                           │
                           │ User enters email, password, name
                           ▼
                    ┌──────────────┐
                    │ AuthRepository│
                    │  .register() │
                    └──────┬───────┘
                           │
                           │ Supabase Auth API Call
                           ▼
              ┌────────────────────────┐
              │  Supabase Auth Service │
              │  signUp()              │
              └───────────┬────────────┘
                          │
                          │ Creates auth.users entry
                          │ Returns JWT token
                          ▼
              ┌────────────────────────┐
              │  Trigger Function      │
              │  handle_new_user()     │
              └───────────┬────────────┘
                          │
                          │ Auto-creates profile
                          ▼
              ┌────────────────────────┐
              │  profiles table        │
              │  INSERT profile        │
              │  - id (from auth.users)│
              │  - email               │
              │  - full_name           │
              └───────────┬────────────┘
                          │
                          │ Returns AppAuthResponse
                          ▼
                    ┌──────────────┐
                    │ Navigate to  │
                    │ Home Screen  │
                    └──────────────┘
```

### Authentication Components Explained

**1. Login Screen (`login_screen.dart`)**
- UI for email/password input
- Handles both login and registration
- Calls `AuthRepository` methods

**2. Auth Repository (`auth_repo.dart`)**
- Abstraction layer for authentication
- Methods: `login()`, `register()`, `getMe()`, `signOut()`
- Handles Supabase API calls
- Manages user profile data

**3. Supabase Auth Service**
- Cloud-based authentication service
- Handles password hashing
- Issues JWT tokens
- Manages user sessions

**4. Profile Management**
- `profiles` table stores user metadata
- Auto-created via database trigger
- Row Level Security (RLS) policies ensure data privacy

**5. Token Management**
- JWT tokens stored in Supabase session
- Automatically attached to API requests via Dio interceptor
- Tokens refresh automatically when expired

---

## Moments Management Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    MOMENTS MANAGEMENT FLOW                      │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    CREATE MOMENT FLOW                           │
└──────────────────────────────────────────────────────────────────┘

        ┌──────────────────┐
        │ Create Moment    │
        │ Screen           │
        └────────┬─────────┘
                 │
                 │ User fills form:
                 │ - Title, description
                 │ - Target amount
                 │ - Deadline
                 │
                 ▼
        ┌──────────────────┐
        │ Submit Button    │
        └────────┬─────────┘
                 │
                 │ Calls repository
                 ▼
        ┌──────────────────┐
        │ MomentsRepository│
        │ .createMoment()  │
        └────────┬─────────┘
                 │
                 │ POST /api/v1/moments
                 │ Headers: Authorization: Bearer {token}
                 │ Body: {title, description, targetAmount, deadline}
                 ▼
        ┌──────────────────┐
        │ REST API Backend │
        └────────┬─────────┘
                 │
                 │ Validates & creates moment
                 │ Returns moment object
                 ▼
        ┌──────────────────┐
        │ Moment Model      │
        │ fromJson()        │
        └────────┬─────────┘
                 │
                 │ Updates state
                 ▼
        ┌──────────────────┐
        │ momentsListProvider│
        │ Refreshes list    │
        └────────┬─────────┘
                 │
                 │ Navigate to detail
                 ▼
        ┌──────────────────┐
        │ Moment Detail     │
        │ Screen            │
        └──────────────────┘
```

```
┌──────────────────────────────────────────────────────────────────┐
│                    VIEW MOMENTS LIST FLOW                       │
└──────────────────────────────────────────────────────────────────┘

        ┌──────────────────┐
        │ Moments Home     │
        │ Screen           │
        └────────┬─────────┘
                 │
                 │ Widget builds
                 │ Watches provider
                 ▼
        ┌──────────────────┐
        │ momentsListProvider│
        │ FutureProvider   │
        └────────┬─────────┘
                 │
                 │ Calls repository
                 ▼
        ┌──────────────────┐
        │ MomentsRepository│
        │ .getMoments()    │
        └────────┬─────────┘
                 │
                 │ GET /api/v1/moments
                 │ Headers: Authorization: Bearer {token}
                 ▼
        ┌──────────────────┐
        │ REST API Backend │
        └────────┬─────────┘
                 │
                 │ Returns list of moments
                 │ [{moment1}, {moment2}, ...]
                 ▼
        ┌──────────────────┐
        │ Parse JSON       │
        │ Moment.fromJson()│
        └────────┬─────────┘
                 │
                 │ Returns List<Moment>
                 ▼
        ┌──────────────────┐
        │ Provider State   │
        │ Updates UI       │
        └────────┬─────────┘
                 │
                 │ Displays list
                 ▼
        ┌──────────────────┐
        │ ListView Widget  │
        │ Shows moments    │
        └──────────────────┘
```

```
┌──────────────────────────────────────────────────────────────────┐
│                    MOMENT DETAIL FLOW                            │
└──────────────────────────────────────────────────────────────────┘

        ┌──────────────────┐
        │ Moment Detail    │
        │ Screen           │
        │ (momentId)       │
        └────────┬─────────┘
                 │
                 │ Watches provider
                 │ momentDetailProvider(momentId)
                 ▼
        ┌──────────────────┐
        │ momentDetailProvider│
        │ FutureProvider.family│
        └────────┬─────────┘
                 │
                 │ Calls repository
                 ▼
        ┌──────────────────┐
        │ MomentsRepository│
        │ .getMomentDetail()│
        └────────┬─────────┘
                 │
                 │ GET /api/v1/moments/{id}
                 │ Headers: Authorization: Bearer {token}
                 ▼
        ┌──────────────────┐
        │ REST API Backend │
        └────────┬─────────┘
                 │
                 │ Returns moment detail:
                 │ - Basic moment info
                 │ - Health status (GREEN/YELLOW/RED)
                 │ - Guidance nudges
                 │ - Participants list
                 │ - Contributions list
                 ▼
        ┌──────────────────┐
        │ MomentDetail Model│
        │ fromJson()       │
        └────────┬─────────┘
                 │
                 │ Updates state
                 ▼
        ┌──────────────────┐
        │ Provider State   │
        │ Updates UI       │
        └────────┬─────────┘
                 │
                 │ Displays:
                 │ - Health badge
                 │ - Progress card
                 │ - Guidance card
                 │ - Participants
                 │ - Contributions
                 ▼
        ┌──────────────────┐
        │ Detail UI        │
        │ Components       │
        └──────────────────┘
```

### Moments Operations Explained

**1. Create Moment**
- User fills form with moment details
- Repository sends POST request to API
- Backend validates and creates moment
- State refreshes to show new moment

**2. List Moments**
- Provider automatically fetches on screen load
- Repository calls GET endpoint
- Backend returns user's moments
- UI displays list with health badges

**3. View Moment Detail**
- Provider fetches full moment data
- Includes health calculation and guidance
- Shows participants and contributions
- Real-time updates when data changes

**4. Add Participant**
- User enters email and role
- Repository sends POST to participants endpoint
- Backend adds participant to moment
- Detail screen refreshes

**5. Add Contribution**
- User enters amount and optional note
- Repository sends POST to contributions endpoint
- Backend records contribution
- Health status recalculates
- UI updates with new progress

**6. Close Moment**
- User confirms closure
- Repository sends POST to close endpoint
- Backend marks moment as closed
- Summary screen shows final stats

---

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATA FLOW ARCHITECTURE                      │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐
│   UI Layer   │  (Screens & Widgets)
│              │
│ - LoginScreen│
│ - MomentsHome│
│ - MomentDetail│
└──────┬───────┘
       │
       │ User Actions
       │ State Changes
       ▼
┌──────────────┐
│ State Layer  │  (Riverpod Providers)
│              │
│ - momentsList│
│   Provider   │
│ - momentDetail│
│   Provider   │
└──────┬───────┘
       │
       │ Calls Repository Methods
       │ Watches for Changes
       ▼
┌──────────────┐
│ Data Layer   │  (Repositories)
│              │
│ - AuthRepo   │
│ - MomentsRepo│
└──────┬───────┘
       │
       │ Makes API Calls
       │ Handles Errors
       ▼
┌──────────────┐
│ Network Layer│  (Dio Client)
│              │
│ - DioClient  │
│ - Interceptors│
└──────┬───────┘
       │
       │ HTTP Requests
       │ Adds Auth Headers
       ▼
┌──────────────┐
│ Backend APIs │
│              │
│ - Supabase   │
│ - REST API   │
└──────┬───────┘
       │
       │ Returns Data
       │ JSON Responses
       ▼
┌──────────────┐
│ Models Layer │  (Data Models)
│              │
│ - User       │
│ - Moment     │
│ - MomentDetail│
└──────┬───────┘
       │
       │ Parses JSON
       │ Creates Objects
       ▼
┌──────────────┐
│ State Layer  │  (Updates Providers)
└──────┬───────┘
       │
       │ Notifies Listeners
       │ Rebuilds UI
       ▼
┌──────────────┐
│   UI Layer   │  (Displays Data)
└──────────────┘
```

### Data Flow Explanation

**Unidirectional Data Flow:**
1. **UI → State**: User interactions trigger state changes
2. **State → Data**: Providers call repository methods
3. **Data → Network**: Repositories make API calls
4. **Network → Backend**: HTTP requests sent to APIs
5. **Backend → Models**: JSON responses parsed into models
6. **Models → State**: Providers update with new data
7. **State → UI**: UI rebuilds with updated state

**Benefits:**
- Predictable data flow
- Easy to debug
- Clear separation of concerns
- Testable components

---

## State Management Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    STATE MANAGEMENT FLOW                       │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    RIVERPOD PROVIDER HIERARCHY                 │
└──────────────────────────────────────────────────────────────────┘

ProviderScope (Root)
│
├─► dioClientProvider
│   └─► Provides: DioClient instance
│       └─► Used by: All repositories
│
├─► momentsRepoProvider
│   └─► Depends on: dioClientProvider
│   └─► Provides: MomentsRepository instance
│       └─► Used by: State providers
│
├─► momentsListProvider
│   └─► Type: FutureProvider<List<Moment>>
│   └─► Depends on: momentsRepoProvider
│   └─► Provides: List of moments
│       └─► Used by: MomentsHomeScreen
│
└─► momentDetailProvider(momentId)
    └─► Type: FutureProvider.family<MomentDetail, String>
    └─► Depends on: momentsRepoProvider
    └─► Provides: Single moment detail
        └─► Used by: MomentDetailScreen
```

### State Management Explained

**1. Provider Scope**
- Wraps entire app
- Provides dependency injection container
- Manages provider lifecycle

**2. Infrastructure Providers**
- `dioClientProvider`: Creates HTTP client
- `momentsRepoProvider`: Creates repository instance
- Singleton pattern ensures single instance

**3. State Providers**
- `momentsListProvider`: Manages list of moments
  - Type: `FutureProvider<List<Moment>>`
  - Automatically handles loading/error states
  - Refreshes when dependencies change

- `momentDetailProvider`: Manages single moment
  - Type: `FutureProvider.family<MomentDetail, String>`
  - Family provider allows multiple instances (one per momentId)
  - Caches results per momentId

**4. Provider Usage in UI**
```dart
// Watching provider (auto-rebuilds on change)
final momentsAsync = ref.watch(momentsListProvider);

// Reading provider (one-time read)
final moments = ref.read(momentsListProvider);

// Refreshing provider (re-fetch data)
ref.refresh(momentsListProvider);
```

**5. State Lifecycle**
- **Loading**: Shows loading indicator
- **Data**: Displays data
- **Error**: Shows error message
- **Refresh**: Re-fetches when needed

---

## API Request Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    API REQUEST FLOW                             │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    REQUEST PIPELINE                             │
└──────────────────────────────────────────────────────────────────┘

1. UI Component
   │
   │ User action triggers
   │
   ▼
2. Provider/Repository
   │
   │ Calls repository method
   │ Example: repo.getMoments()
   │
   ▼
3. DioClient
   │
   │ Creates Dio instance
   │ Sets base URL
   │
   ▼
4. Request Interceptor
   │
   │ onRequest() hook
   │ ├─► Gets Supabase session
   │ ├─► Extracts access token
   │ └─► Adds Authorization header
   │     Header: "Bearer {token}"
   │
   ▼
5. HTTP Request
   │
   │ GET/POST/PATCH/DELETE
   │ URL: baseUrl + endpoint
   │ Headers: Content-Type, Authorization
   │ Body: JSON (if POST/PATCH)
   │
   ▼
6. REST API Backend
   │
   │ Validates token
   │ Processes request
   │ Returns response
   │
   ▼
7. Response Interceptor
   │
   │ Checks status code
   │ Handles errors
   │
   ▼
8. Error Handling
   │
   │ onError() hook
   │ ├─► 401 Unauthorized → Sign out user
   │ ├─► Other errors → Throw exception
   │ └─► Returns error to caller
   │
   ▼
9. Repository
   │
   │ Parses response
   │ Converts JSON to models
   │ Returns typed objects
   │
   ▼
10. Provider
    │
    │ Updates state
    │ Notifies listeners
    │
    ▼
11. UI Component
    │
    │ Rebuilds with new data
    │ Displays updated UI
```

### API Request Components Explained

**1. Dio Client Setup**
```dart
DioClient() {
  _dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,  // http://localhost:8000/api/v1
    headers: {'Content-Type': 'application/json'},
  ));
}
```

**2. Request Interceptor**
- Runs before every request
- Gets current Supabase session
- Extracts JWT access token
- Adds `Authorization: Bearer {token}` header
- Ensures authenticated requests

**3. Error Interceptor**
- Runs on error responses
- Handles 401 Unauthorized:
  - Token expired or invalid
  - Signs out user automatically
  - Redirects to login
- Other errors propagate to UI

**4. Response Handling**
- Success: JSON parsed into models
- Error: Exception thrown with message
- Repository catches and wraps errors

**5. Token Management**
- Tokens stored in Supabase session
- Automatically refreshed by Supabase
- Interceptor always uses latest token
- No manual token management needed

---

## Component Interaction Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMPONENT INTERACTION                       │
└─────────────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │  main.dart      │
                    │  - Initializes  │
                    │  - Sets routes  │
                    └────────┬────────┘
                             │
                             │ Creates
                             ▼
        ┌────────────────────────────────────┐
        │  ProviderScope                     │
        │  - Wraps app                       │
        │  - Provides DI container           │
        └────────┬───────────────────────────┘
                 │
                 │ Contains
                 ▼
        ┌────────────────────────────────────┐
        │  MaterialApp                      │
        │  - Theme configuration            │
        │  - Router setup                   │
        └────────┬───────────────────────────┘
                 │
                 │ Routes to
                 ▼
    ┌────────────┴────────────┐
    │                         │
    ▼                         ▼
┌──────────┐          ┌──────────────┐
│ Login    │          │ Moments Home │
│ Screen   │          │ Screen       │
└────┬─────┘          └──────┬───────┘
     │                       │
     │ Uses                 │ Uses
     ▼                       ▼
┌──────────┐          ┌──────────────┐
│ AuthRepo │          │ momentsList │
│          │          │ Provider    │
└────┬─────┘          └──────┬───────┘
     │                       │
     │ Uses                  │ Uses
     ▼                       ▼
┌──────────┐          ┌──────────────┐
│ Supabase │          │ MomentsRepo  │
│ Client   │          └──────┬───────┘
└──────────┘                 │
                             │ Uses
                             ▼
                    ┌──────────────┐
                    │ DioClient    │
                    │ - Interceptors│
                    └──────┬───────┘
                           │
                           │ Makes requests
                           ▼
                    ┌──────────────┐
                    │ REST API     │
                    │ Backend      │
                    └──────────────┘
```

### Component Responsibilities

**1. main.dart**
- App entry point
- Initializes Supabase
- Sets up routing
- Configures theme

**2. ProviderScope**
- Root widget for Riverpod
- Provides dependency injection
- Manages provider lifecycle

**3. MaterialApp**
- Material Design wrapper
- Navigation configuration
- Theme application

**4. Screens**
- UI components
- User interactions
- Display data from providers

**5. Providers**
- State management
- Business logic coordination
- Data fetching orchestration

**6. Repositories**
- Data access abstraction
- API communication
- Error handling

**7. Network Layer**
- HTTP client configuration
- Request/response interceptors
- Authentication handling

**8. Backend Services**
- Supabase: Authentication
- REST API: Business logic

---

## Process Summary

### Key Processes in Momentra

**1. User Authentication Process**
- Registration → Supabase Auth → Profile Creation → Session Management
- Login → Credential Validation → Token Generation → Session Storage
- Token Usage → Automatic Header Injection → API Authentication

**2. Moments Management Process**
- Create → Form Input → API Call → State Update → UI Refresh
- List → Provider Fetch → API Call → Parse Models → Display
- Detail → Provider Fetch → API Call → Health Calculation → Display

**3. Data Synchronization Process**
- Local State → Provider → Repository → API → Backend → Response → Models → Provider → UI

**4. Error Handling Process**
- API Error → Interceptor → Error Type Check → User Notification → State Update

**5. State Management Process**
- User Action → Provider Method → Repository Call → API Request → Response → Model Creation → Provider Update → UI Rebuild

---

## Technology Stack Details

### Frontend Technologies

| Technology | Purpose | Version |
|------------|---------|---------|
| Flutter | UI Framework | 3.x |
| Dart | Programming Language | 3.10.0+ |
| Riverpod | State Management | 2.4.9 |
| Dio | HTTP Client | 5.4.0 |
| Supabase Flutter | Auth & Backend | 2.8.0 |
| SharedPreferences | Local Storage | 2.2.2 |

### Backend Services

| Service | Purpose | Protocol |
|---------|---------|----------|
| Supabase Auth | Authentication | REST API |
| Supabase Database | User Profiles | PostgreSQL |
| REST API Backend | Business Logic | REST API |

### Architecture Patterns

1. **Feature-Based Architecture**: Self-contained feature modules
2. **Repository Pattern**: Data access abstraction
3. **Provider Pattern**: State management and dependency injection
4. **Unidirectional Data Flow**: Predictable state updates
5. **Separation of Concerns**: Clear layer boundaries

---

This document provides a comprehensive overview of Momentra's technology stack, processes, and data flows. Each component works together to create a scalable, maintainable mobile application.
