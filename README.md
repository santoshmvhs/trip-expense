# Momentra MVP

Complete end-to-end MVP for moment-centric financial orchestration platform.

## Quick Start

### Prerequisites
- Python 3.11+
- Flutter 3.x
- Docker & Docker Compose
- MongoDB (via Docker)

### 1. Start MongoDB

```bash
cd backend
docker-compose up -d mongodb
```

### 2. Setup Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Seed Data (Optional)

```bash
cd backend
python seed_data.py
```

This creates:
- User: `demo@momentra.com` / `demo123`
- 3 demo moments

### 4. Run Backend

```bash
cd backend
./run_backend.sh
# Or: uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend runs on: `http://localhost:8000`

### 5. Setup Flutter

```bash
flutter pub get
```

### 6. Run Flutter App

```bash
flutter run
```

For Android emulator, API base URL is configured to `http://10.0.2.2:8000`.
For iOS simulator, update `lib/core/constants.dart` to use `http://localhost:8000`.

## Running Tests

### Backend Tests

```bash
cd backend
pytest
```

### Flutter Tests

```bash
flutter test
```

## Project Structure

```
momentra/
├── backend/              # FastAPI backend
│   ├── app/
│   │   ├── api/         # API routes
│   │   ├── core/        # Config, DB, Security
│   │   ├── db/          # Repositories
│   │   ├── models/      # Pydantic models
│   │   ├── services/    # Business logic
│   │   └── tests/       # Tests
│   ├── docker-compose.yml
│   ├── requirements.txt
│   └── seed_data.py
│
└── lib/                  # Flutter frontend
    ├── app/             # Router, Theme
    ├── core/            # Network, Storage
    ├── features/        # Auth, Moments
    ├── widgets/         # Reusable widgets
    └── main.dart
```

## API Endpoints

- `POST /api/v1/auth/register` - Register user
- `POST /api/v1/auth/login` - Login
- `GET /api/v1/auth/me` - Get current user
- `POST /api/v1/moments` - Create moment
- `GET /api/v1/moments` - List moments
- `GET /api/v1/moments/{id}` - Get moment detail (with health & guidance)
- `PATCH /api/v1/moments/{id}` - Update moment
- `POST /api/v1/moments/{id}/close` - Close moment
- `GET /api/v1/moments/{id}/summary` - Get summary
- `POST /api/v1/moments/{id}/participants` - Add participant
- `GET /api/v1/moments/{id}/participants` - List participants
- `POST /api/v1/moments/{id}/contributions` - Add contribution
- `GET /api/v1/moments/{id}/contributions` - List contributions

## Features

✅ User authentication (JWT)
✅ Create/update/list moments
✅ Add participants
✅ Add manual contributions
✅ Moment health calculation (GREEN/YELLOW/RED)
✅ Rule-based guidance nudges
✅ Close moment & summary

## Health Calculation Rules

- **GREEN/on-track**: gap <= 0.10
- **YELLOW/at-risk**: 0.10 < gap <= 0.25
- **RED/critical**: gap > 0.25
- **Funded**: Force GREEN if funding_ratio >= 1.0
- **Overdue**: Force RED if deadline passed and not funded

## Development

### Backend Environment Variables

Create `backend/.env`:
```
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=momentra
SECRET_KEY=your-secret-key
DEBUG=True
```

### Flutter Configuration

Update API base URL in `lib/core/constants.dart` for your platform.
