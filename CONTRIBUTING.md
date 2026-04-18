# Contributing to OpenAir

Thank you for contributing! Please read this before starting.

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Go | 1.22+ | https://go.dev/dl |
| Flutter | 3.22+ | https://flutter.dev/docs/get-started/install |
| Node.js | 20+ | https://nodejs.org |
| Docker + Compose | Latest | https://docs.docker.com/get-docker |
| GitHub CLI | Latest | https://cli.github.com |

## First-time setup

### 1. Clone and configure
```bash
git clone https://github.com/TgkCapture/openair.git
cd openair
cp .env.example .env
# Edit .env with your local values
```

### 2. Firebase (Flutter only)
Follow the instructions in `mobile/FIREBASE_SETUP.md`

### 3. Start all services
```bash
docker-compose up --build
```

### 4. Verify everything is running
```bash
# Backend health check
curl http://localhost:8000/health
# → {"status":"ok","service":"openair-api","version":"1.0.0"}

# Adminer (database UI)
open http://localhost:8090
# Server: postgres, User: openair, Password: changeme, Database: openair_db

# Admin dashboard
open http://localhost:5173

# Streaming server
open http://localhost:8080/health
```

## Branch naming
feat/issue-id-short-description   # new features
fix/issue-id-short-description    # bug fixes
chore/short-description            # maintenance

Example: `feat/auth-01-registration`

## Commit messages

Always reference the issue to auto-close it on merge to develop:
feat: add user registration endpoint, closes #8
fix: correct JWT expiry calculation, closes #12

## Pull Request process

1. Branch off `develop`
2. Write your code
3. Make sure `docker-compose up` still works
4. Push and open a PR against `develop`
5. CI must be green before merging
6. Request a review from @TgkCapture

## Code style

- **Go:** run `gofmt ./...` before committing
- **Flutter:** run `dart format .` before committing  
- **React:** ESLint runs in CI — fix all warnings

## Questions?

Open a GitHub Discussion or tag @TgkCapture in the relevant issue.
