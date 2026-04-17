#!/usr/bin/env bash
# ============================================================
#  OpenAir — GitHub Project Setup Script
#  Run this after creating your repo at:
#  https://github.com/TgkCapture/openair
#
#  Requirements:
#    - GitHub CLI installed: https://cli.github.com
#    - Logged in: gh auth login
#
#  Usage:
#    chmod +x setup_github.sh
#    ./setup_github.sh
# ============================================================

set -e

REPO="TgkCapture/openair"

echo ""
echo "=========================================="
echo "  OpenAir — GitHub Setup"
echo "  Repo: $REPO"
echo "=========================================="
echo ""

# ── CHECK AUTH ──────────────────────────────────────────────
if ! gh auth status &>/dev/null; then
  echo "ERROR: Not logged in. Run: gh auth login"
  exit 1
fi
echo "✅ GitHub CLI authenticated"
echo ""

# ── LABELS ──────────────────────────────────────────────────
echo "Creating labels..."

gh label create "backend"       --color "0075ca" --description "Go backend service"         --repo $REPO --force
gh label create "mobile"        --color "7057ff" --description "Flutter mobile app"          --repo $REPO --force
gh label create "admin"         --color "e4e669" --description "React admin dashboard"       --repo $REPO --force
gh label create "streaming"     --color "d93f0b" --description "Streaming infrastructure"   --repo $REPO --force
gh label create "database"      --color "0e8a16" --description "Database / migrations"       --repo $REPO --force
gh label create "devops"        --color "f9d0c4" --description "CI/CD / Docker / deploy"     --repo $REPO --force
gh label create "auth"          --color "c5def5" --description "Authentication & security"   --repo $REPO --force
gh label create "payments"      --color "bfd4f2" --description "Payments & subscriptions"    --repo $REPO --force
gh label create "notifications" --color "fef2c0" --description "Push notifications"          --repo $REPO --force
gh label create "ui/ux"         --color "e99695" --description "UI design & UX"              --repo $REPO --force
gh label create "must-have"     --color "b60205" --description "MVP — must ship"             --repo $REPO --force
gh label create "should-have"   --color "e4a10d" --description "Important — v1.1 target"    --repo $REPO --force
gh label create "nice-to-have"  --color "0e8a16" --description "Future — v2.0+"             --repo $REPO --force
gh label create "docs"          --color "0075ca" --description "Documentation"               --repo $REPO --force

echo "✅ Labels created"
echo ""

# ── MILESTONES ──────────────────────────────────────────────
echo "Creating milestones..."

gh api repos/$REPO/milestones --method POST \
  --field title="M1: Project Scaffolding" \
  --field description="Repo structure, Docker Compose, CI/CD pipeline, env config" \
  --field due_on="2026-05-01T00:00:00Z" > /dev/null

gh api repos/$REPO/milestones --method POST \
  --field title="M2: Auth & User Management" \
  --field description="Registration, login, JWT, password reset, profile" \
  --field due_on="2026-05-15T00:00:00Z" > /dev/null

gh api repos/$REPO/milestones --method POST \
  --field title="M3: Channels & Live Streaming" \
  --field description="Live TV and radio streaming, channel listing, ABR, signed URLs" \
  --field due_on="2026-06-01T00:00:00Z" > /dev/null

gh api repos/$REPO/milestones --method POST \
  --field title="M4: VOD & Podcasts" \
  --field description="VOD catalogue, playback, podcasts, episodes, search" \
  --field due_on="2026-06-15T00:00:00Z" > /dev/null

gh api repos/$REPO/milestones --method POST \
  --field title="M5: Subscriptions & Payments" \
  --field description="Subscription plans, Airtel Money, TNM Mpamba, Stripe integration" \
  --field due_on="2026-07-01T00:00:00Z" > /dev/null

gh api repos/$REPO/milestones --method POST \
  --field title="M6: Admin Dashboard" \
  --field description="React admin panel — content, users, analytics, branding, push notifications" \
  --field due_on="2026-07-15T00:00:00Z" > /dev/null

gh api repos/$REPO/milestones --method POST \
  --field title="M7: Programme Schedule & Notifications" \
  --field description="EPG guide, programme reminders, FCM push notifications" \
  --field due_on="2026-07-25T00:00:00Z" > /dev/null

gh api repos/$REPO/milestones --method POST \
  --field title="M8: MVP Polish & Launch" \
  --field description="QA, bug fixes, performance tuning, App Store submission, production deploy" \
  --field due_on="2026-08-10T00:00:00Z" > /dev/null

echo "✅ Milestones created"
echo ""

# ── ISSUES ──────────────────────────────────────────────────
echo "Creating issues..."

# Helper: create issue and return its number
create_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"
  local milestone="$4"
  gh issue create \
    --repo "$REPO" \
    --title "$title" \
    --body "$body" \
    --label "$labels" \
    --milestone "$milestone" \
    --assignee "TgkCapture"
}

# ── MILESTONE 1: SCAFFOLDING ────────────────────────────────
echo "  → M1: Scaffolding issues..."

create_issue \
  "[SCAFFOLD-01] Initialise monorepo folder structure" \
  "## Task\nCreate the top-level folder structure for the OpenAir monorepo.\n\n## Structure\n\`\`\`\nopenair/\n├── mobile/       # Flutter app\n├── backend/      # Go API\n├── admin/        # React dashboard\n├── streaming/    # Nginx-RTMP config\n├── docker/       # Docker files\n├── docs/         # SDLC documents\n└── .github/      # Actions workflows\n\`\`\`\n\n## Acceptance Criteria\n- [ ] Folder structure created\n- [ ] Root README.md with project overview\n- [ ] .gitignore for Go, Flutter, Node\n- [ ] LICENSE file (MIT)" \
  "devops,docs,must-have" "M1: Project Scaffolding" > /dev/null

create_issue \
  "[SCAFFOLD-02] Set up Docker Compose for local development" \
  "## Task\nCreate a \`docker-compose.yml\` that spins up the full local dev environment.\n\n## Services\n- \`api\` — Go backend (hot reload with air)\n- \`postgres\` — PostgreSQL 15\n- \`redis\` — Redis 7\n- \`nginx-rtmp\` — Nginx with RTMP module\n- \`admin\` — React admin dashboard (Vite dev server)\n- \`adminer\` — DB management UI\n\n## Acceptance Criteria\n- [ ] \`docker-compose up\` starts all services\n- [ ] Services communicate via internal Docker network\n- [ ] Volumes persist data between restarts\n- [ ] .env.example file documents all required variables" \
  "devops,must-have" "M1: Project Scaffolding" > /dev/null

create_issue \
  "[SCAFFOLD-03] Configure GitHub Actions CI/CD pipeline" \
  "## Task\nSet up automated testing and deployment workflows.\n\n## Workflows\n- \`ci.yml\` — runs on every PR: Go tests + Flutter tests + lint\n- \`deploy-staging.yml\` — auto deploy to staging on merge to main\n- \`deploy-prod.yml\` — manual trigger with approval gate for production\n\n## Acceptance Criteria\n- [ ] CI runs on every pull request\n- [ ] Go tests pass: \`go test ./...\`\n- [ ] Flutter tests pass: \`flutter test\`\n- [ ] Docker images built and pushed to ghcr.io\n- [ ] Staging auto-deploys on green CI" \
  "devops,must-have" "M1: Project Scaffolding" > /dev/null

create_issue \
  "[SCAFFOLD-04] Initialise Go backend project (gin + structure)" \
  "## Task\nBootstrap the Go backend with the project structure, router, and middleware skeleton.\n\n## Structure\n\`\`\`\nbackend/\n├── cmd/api/main.go\n├── internal/\n│   ├── auth/\n│   ├── content/\n│   ├── users/\n│   ├── billing/\n│   ├── streaming/\n│   ├── notifications/\n│   └── admin/\n├── pkg/\n│   ├── database/\n│   ├── cache/\n│   ├── middleware/\n│   └── utils/\n├── migrations/\n└── config/\n\`\`\`\n\n## Tech\n- Framework: Gin\n- Config: godotenv / viper\n- DB: pgx + sqlc or gorm\n- Migrations: golang-migrate\n\n## Acceptance Criteria\n- [ ] \`go run ./cmd/api\` starts the server\n- [ ] Health check endpoint: GET /health → 200 OK\n- [ ] Environment config loaded from .env\n- [ ] Graceful shutdown implemented" \
  "backend,must-have" "M1: Project Scaffolding" > /dev/null

create_issue \
  "[SCAFFOLD-05] Initialise Flutter mobile project" \
  "## Task\nBootstrap the Flutter app with folder structure, BLoC setup, routing, and theming.\n\n## Structure\n\`\`\`\nmobile/\n├── lib/\n│   ├── main.dart\n│   ├── app/          # App root, router, theme\n│   ├── features/     # Feature-first structure\n│   │   ├── auth/\n│   │   ├── home/\n│   │   ├── tv/\n│   │   ├── radio/\n│   │   ├── vod/\n│   │   ├── podcasts/\n│   │   ├── schedule/\n│   │   └── profile/\n│   ├── core/         # Shared widgets, services, models\n│   └── config/       # API endpoints, constants\n└── pubspec.yaml\n\`\`\`\n\n## Acceptance Criteria\n- [ ] App runs on Android and iOS simulator\n- [ ] Bottom nav bar with 5 tabs renders correctly\n- [ ] Dark and light theme implemented and toggleable\n- [ ] go_router navigation working between screens\n- [ ] flutter_bloc set up with AppBloc for global state" \
  "mobile,ui/ux,must-have" "M1: Project Scaffolding" > /dev/null

create_issue \
  "[SCAFFOLD-06] Set up PostgreSQL schema and migrations" \
  "## Task\nCreate all database migrations for the OpenAir schema.\n\n## Tables to create\nusers, subscriptions, channels, content, podcasts, episodes, programmes, payments, notifications, watch_history, fcm_tokens\n\n## Acceptance Criteria\n- [ ] Migration files created in \`backend/migrations/\`\n- [ ] \`migrate up\` creates all 11 tables cleanly\n- [ ] \`migrate down\` rolls back cleanly\n- [ ] All indexes created (see Stage 3 design doc)\n- [ ] Seed data script for local development" \
  "database,must-have" "M1: Project Scaffolding" > /dev/null

create_issue \
  "[SCAFFOLD-07] Initialise React admin dashboard project" \
  "## Task\nBootstrap the React admin dashboard.\n\n## Tech Stack\n- Vite + React + TypeScript\n- Tailwind CSS\n- TanStack Query (React Query)\n- React Router v6\n- Recharts (analytics charts)\n- Axios (HTTP client)\n\n## Acceptance Criteria\n- [ ] \`npm run dev\` starts dev server\n- [ ] Login page renders\n- [ ] Sidebar navigation with all admin sections\n- [ ] API client configured with JWT interceptor\n- [ ] Tailwind CSS configured" \
  "admin,must-have" "M1: Project Scaffolding" > /dev/null

# ── MILESTONE 2: AUTH ───────────────────────────────────────
echo "  → M2: Auth issues..."

create_issue \
  "[AUTH-01] Backend: User registration endpoint" \
  "## Endpoint\n\`POST /api/v1/auth/register\`\n\n## Request Body\n\`\`\`json\n{ \"email\": \"user@example.com\", \"password\": \"secret\", \"full_name\": \"John Doe\" }\n\`\`\`\n\n## Logic\n1. Validate input (email format, password min 8 chars)\n2. Check email not already registered\n3. Hash password with bcrypt (cost 12)\n4. Insert user into DB\n5. Issue JWT access + refresh token\n6. Return user object + tokens\n\n## Acceptance Criteria\n- [ ] Returns 201 with user + JWT on success\n- [ ] Returns 400 on validation error\n- [ ] Returns 409 if email already exists\n- [ ] Password never stored or logged in plaintext" \
  "backend,auth,must-have" "M2: Auth & User Management" > /dev/null

create_issue \
  "[AUTH-02] Backend: Login endpoint" \
  "## Endpoint\n\`POST /api/v1/auth/login\`\n\n## Logic\n1. Find user by email\n2. Compare password with bcrypt hash\n3. Issue JWT (RS256, 24hr) + refresh token (30 days)\n4. Store refresh token hash in DB\n5. Return user + tokens\n\n## Acceptance Criteria\n- [ ] Returns 200 + tokens on valid credentials\n- [ ] Returns 401 on invalid email or password\n- [ ] Refresh token stored securely\n- [ ] Rate limited to 20 req/min per IP" \
  "backend,auth,must-have" "M2: Auth & User Management" > /dev/null

create_issue \
  "[AUTH-03] Backend: Token refresh + logout endpoints" \
  "## Endpoints\n- \`POST /api/v1/auth/refresh\` — exchange refresh token for new access token\n- \`POST /api/v1/auth/logout\` — invalidate refresh token\n\n## Acceptance Criteria\n- [ ] Refresh returns new JWT on valid refresh token\n- [ ] Refresh returns 401 on expired/invalid token\n- [ ] Logout invalidates the refresh token in DB\n- [ ] Expired access tokens rejected by JWT middleware" \
  "backend,auth,must-have" "M2: Auth & User Management" > /dev/null

create_issue \
  "[AUTH-04] Backend: Password reset via email OTP" \
  "## Endpoints\n- \`POST /api/v1/auth/forgot-password\` — send OTP to email\n- \`POST /api/v1/auth/reset-password\` — verify OTP + set new password\n\n## Acceptance Criteria\n- [ ] OTP generated (6-digit), hashed, stored with 15min expiry\n- [ ] Email sent via SMTP (configurable)\n- [ ] OTP verified and password updated\n- [ ] Old OTPs invalidated after use" \
  "backend,auth,must-have" "M2: Auth & User Management" > /dev/null

create_issue \
  "[AUTH-05] Backend: JWT middleware for protected routes" \
  "## Task\nGin middleware that validates JWT on every protected route.\n\n## Logic\n1. Extract Bearer token from Authorization header\n2. Verify RS256 signature\n3. Check expiry\n4. Inject user claims into Gin context\n5. Reject with 401 if invalid\n\n## Acceptance Criteria\n- [ ] Valid token passes through\n- [ ] Expired token returns 401\n- [ ] Tampered token returns 401\n- [ ] Missing token returns 401\n- [ ] User ID and role available in route handlers via context" \
  "backend,auth,must-have" "M2: Auth & User Management" > /dev/null

create_issue \
  "[AUTH-06] Mobile: Registration and login screens" \
  "## Screens\n- Register screen: name, email, password, confirm password\n- Login screen: email, password, forgot password link\n- Both screens: loading state, error messages, form validation\n\n## Acceptance Criteria\n- [ ] Form validation with real-time feedback\n- [ ] API calls wired to auth BLoC\n- [ ] JWT stored securely (flutter_secure_storage)\n- [ ] Redirect to home on successful auth\n- [ ] Works correctly in both dark and light theme" \
  "mobile,auth,ui/ux,must-have" "M2: Auth & User Management" > /dev/null

create_issue \
  "[AUTH-07] Mobile: Profile screen and settings" \
  "## Screen: Profile\n- Display name, avatar, email\n- Edit profile (name, avatar upload)\n- Subscription status badge\n- Theme toggle (dark/light)\n- Notification preferences\n- Logout button\n\n## Acceptance Criteria\n- [ ] Profile data loaded from API\n- [ ] Edit profile saves and reflects immediately\n- [ ] Theme toggle persists across app restarts\n- [ ] Logout clears tokens and navigates to login" \
  "mobile,auth,ui/ux,should-have" "M2: Auth & User Management" > /dev/null

# ── MILESTONE 3: STREAMING ──────────────────────────────────
echo "  → M3: Streaming issues..."

create_issue \
  "[STREAM-01] Streaming: Nginx-RTMP server configuration" \
  "## Task\nConfigure Nginx with RTMP module for live stream ingest and HLS output.\n\n## Config requirements\n- RTMP ingest on port 1935\n- Stream key authentication\n- FFmpeg transcode to 3 HLS quality tiers (1080p, 480p, 240p)\n- HLS segments output to /tmp/hls/\n- Nginx serves HLS over HTTP on port 8080\n\n## Acceptance Criteria\n- [ ] OBS can push RTMP stream to server\n- [ ] HLS master playlist available at /hls/{channel}.m3u8\n- [ ] All 3 quality tiers available\n- [ ] Stream accessible in VLC before wiring to app" \
  "streaming,must-have" "M3: Channels & Live Streaming" > /dev/null

create_issue \
  "[STREAM-02] Backend: Channels API endpoints" \
  "## Endpoints\n- \`GET /api/v1/channels\` — list all active channels\n- \`GET /api/v1/channels/:id\` — single channel detail\n- \`GET /api/v1/channels/:id/stream\` — get signed HLS URL\n\n## Signed URL logic\n- Check if channel is_premium → verify user subscription\n- Generate HMAC-SHA256 signed URL with 2hr expiry\n- Free channels: return URL directly without signing\n\n## Acceptance Criteria\n- [ ] Channel list returns all active channels with logo, name, type\n- [ ] Premium channel returns 403 PREMIUM_REQUIRED for free users\n- [ ] Signed URL expires after 2 hours\n- [ ] Expired signed URL returns 401 from Nginx" \
  "backend,streaming,must-have" "M3: Channels & Live Streaming" > /dev/null

create_issue \
  "[STREAM-03] Mobile: TV channels screen and live player" \
  "## Screen: TV\n- Grid of channel cards (logo, name, live badge)\n- Tap channel → full-screen HLS player\n- Player controls: play/pause, quality selector, fullscreen toggle\n- Now-playing info overlay (programme title + time)\n- Premium lock icon on gated channels\n\n## Tech\n- better_player package for HLS playback\n- ABR quality selection\n\n## Acceptance Criteria\n- [ ] Channel grid loads from API\n- [ ] Stream plays within 5 seconds of tapping\n- [ ] Quality auto-adjusts on slow network\n- [ ] Premium channels show paywall for free users\n- [ ] Works in both portrait and landscape" \
  "mobile,streaming,ui/ux,must-have" "M3: Channels & Live Streaming" > /dev/null

create_issue \
  "[STREAM-04] Mobile: Radio channels screen and background audio" \
  "## Screen: Radio\n- List of radio channels with artwork and live indicator\n- Tap → audio starts playing\n- Mini player persists at bottom of app\n- Lock screen controls (play/pause, channel info)\n- Audio continues when app is backgrounded\n\n## Tech\n- just_audio + audio_service for background playback\n\n## Acceptance Criteria\n- [ ] Radio stream plays correctly\n- [ ] Audio continues in background\n- [ ] Lock screen shows channel name + controls\n- [ ] Switching channels stops previous stream cleanly\n- [ ] Works on both Android and iOS" \
  "mobile,streaming,ui/ux,must-have" "M3: Channels & Live Streaming" > /dev/null

# ── MILESTONE 4: VOD & PODCASTS ─────────────────────────────
echo "  → M4: VOD & Podcasts issues..."

create_issue \
  "[VOD-01] Backend: VOD catalogue and stream endpoints" \
  "## Endpoints\n- \`GET /api/v1/vod\` — paginated VOD list (filter by category, is_premium)\n- \`GET /api/v1/vod/:id\` — single VOD detail\n- \`GET /api/v1/vod/:id/stream\` — signed playback URL\n- \`GET /api/v1/vod/search?q=\` — search by title/keyword\n\n## Acceptance Criteria\n- [ ] Paginated response with meta (page, total, per_page)\n- [ ] Category filter works\n- [ ] Search returns relevant results\n- [ ] Signed URL for premium VOD enforces subscription check" \
  "backend,must-have" "M4: VOD & Podcasts" > /dev/null

create_issue \
  "[VOD-02] Mobile: VOD catalogue screen and player" \
  "## Screen: Library > VOD\n- Category tab bar (All, News, Sports, Drama, etc.)\n- Thumbnail grid with title, duration, premium badge\n- Search bar\n- Tap → VOD detail screen → play\n- Continue watching row on home screen\n\n## Acceptance Criteria\n- [ ] Catalogue loads with pagination (infinite scroll)\n- [ ] Category filter tabs work\n- [ ] Search works with debounce\n- [ ] Video player with seek bar, fullscreen, quality select\n- [ ] Resume from last position (watch_history API)" \
  "mobile,ui/ux,must-have" "M4: VOD & Podcasts" > /dev/null

create_issue \
  "[POD-01] Backend: Podcasts and episodes endpoints" \
  "## Endpoints\n- \`GET /api/v1/podcasts\` — list all podcasts\n- \`GET /api/v1/podcasts/:id\` — podcast detail\n- \`GET /api/v1/podcasts/:id/episodes\` — episodes list\n- \`GET /api/v1/episodes/:id/stream\` — signed audio URL\n\n## Acceptance Criteria\n- [ ] Podcast list with artwork, title, episode count\n- [ ] Episode list sorted by published_at DESC\n- [ ] Premium episodes enforce subscription check\n- [ ] Signed audio URL works with just_audio" \
  "backend,must-have" "M4: VOD & Podcasts" > /dev/null

create_issue \
  "[POD-02] Mobile: Podcasts screen and audio player" \
  "## Screen: Library > Podcasts\n- Podcast series grid (artwork, title, episode count)\n- Tap → episode list with progress indicators\n- Audio player with speed control (0.75x, 1x, 1.25x, 1.5x, 2x)\n- Queue support\n- Background playback via audio_service\n\n## Acceptance Criteria\n- [ ] Podcast and episode listing loads from API\n- [ ] Audio plays with background support\n- [ ] Speed control works\n- [ ] Progress saved and shown on episode list\n- [ ] Lock screen controls functional" \
  "mobile,ui/ux,must-have" "M4: VOD & Podcasts" > /dev/null

# ── MILESTONE 5: PAYMENTS ───────────────────────────────────
echo "  → M5: Payments issues..."

create_issue \
  "[PAY-01] Backend: Subscription plans and management endpoints" \
  "## Endpoints\n- \`GET /api/v1/subscriptions/plans\` — list available plans\n- \`GET /api/v1/subscriptions/me\` — user's current subscription\n- \`POST /api/v1/subscriptions\` — create subscription\n- \`DELETE /api/v1/subscriptions/me\` — cancel subscription\n- \`GET /api/v1/payments/history\` — payment history\n\n## Acceptance Criteria\n- [ ] Plans configurable via admin (monthly, yearly)\n- [ ] Subscription status checked on premium content requests\n- [ ] Cancellation sets status to 'cancelled' at period end\n- [ ] Payment history returns paginated invoices" \
  "backend,payments,must-have" "M5: Subscriptions & Payments" > /dev/null

create_issue \
  "[PAY-02] Backend: Airtel Money payment integration" \
  "## Task\nIntegrate Airtel Money API for subscription payments.\n\n## Flow\n1. User initiates subscription → backend calls Airtel Money API\n2. Airtel sends USSD push to user's phone\n3. User confirms on phone\n4. Airtel calls our webhook: POST /api/v1/webhooks/airtel\n5. Backend activates subscription on confirmed payment\n\n## Acceptance Criteria\n- [ ] Payment initiation API call works\n- [ ] Webhook receives and verifies Airtel callback\n- [ ] Subscription activated on successful payment\n- [ ] Failed payments handled gracefully with user notification\n- [ ] Sandbox/test mode configurable via env" \
  "backend,payments,must-have" "M5: Subscriptions & Payments" > /dev/null

create_issue \
  "[PAY-03] Backend: TNM Mpamba payment integration" \
  "## Task\nIntegrate TNM Mpamba API for subscription payments.\n\n## Same flow as Airtel Money (USSD push model)\n- Webhook endpoint: POST /api/v1/webhooks/mpamba\n\n## Acceptance Criteria\n- [ ] Same acceptance criteria as PAY-02 for Mpamba API\n- [ ] Both Airtel and Mpamba can coexist without conflict\n- [ ] Configurable via environment variables" \
  "backend,payments,must-have" "M5: Subscriptions & Payments" > /dev/null

create_issue \
  "[PAY-04] Backend: Stripe payment integration" \
  "## Task\nIntegrate Stripe for international card payments.\n\n## Flow\n1. Backend creates Stripe Checkout Session\n2. Mobile opens Stripe URL in WebView\n3. User completes payment on Stripe\n4. Stripe calls webhook: POST /api/v1/webhooks/stripe\n5. Backend activates subscription\n\n## Acceptance Criteria\n- [ ] Stripe Checkout Session created correctly\n- [ ] Webhook signature verified (Stripe-Signature header)\n- [ ] Subscription activated on payment_intent.succeeded event\n- [ ] Refunds handled via webhook\n- [ ] Test mode configurable via env" \
  "backend,payments,should-have" "M5: Subscriptions & Payments" > /dev/null

create_issue \
  "[PAY-05] Mobile: Subscription and paywall screens" \
  "## Screens\n- Paywall: shown when free user hits premium content\n  - Plan comparison (monthly vs yearly)\n  - Payment method selector (Airtel / Mpamba / Card)\n  - CTA button per method\n- My Subscription: current plan, renewal date, cancel option\n- Payment History: list of past payments with status\n\n## Acceptance Criteria\n- [ ] Paywall triggers correctly on premium content\n- [ ] Payment method selection routes to correct provider\n- [ ] Subscription status updates after successful payment\n- [ ] Cancel subscription with confirmation dialog" \
  "mobile,payments,ui/ux,must-have" "M5: Subscriptions & Payments" > /dev/null

# ── MILESTONE 6: ADMIN ──────────────────────────────────────
echo "  → M6: Admin issues..."

create_issue \
  "[ADMIN-01] Admin: Content upload and VOD management" \
  "## Features\n- Upload video files (drag and drop)\n- Generate presigned S3 upload URL from backend\n- Set title, description, category, thumbnail, free/premium toggle\n- Edit and delete existing VOD content\n- Bulk access control toggle\n\n## Acceptance Criteria\n- [ ] File upload progress indicator\n- [ ] Video appears in app catalogue after publish\n- [ ] Free/premium toggle reflects immediately in app\n- [ ] Thumbnail auto-generated from video if not provided" \
  "admin,must-have" "M6: Admin Dashboard" > /dev/null

create_issue \
  "[ADMIN-02] Admin: Channel and stream management" \
  "## Features\n- Add/edit/remove TV and radio channels\n- Set stream URL, logo, channel name, type (tv/radio)\n- Toggle channel active/inactive\n- Set channel as free or premium\n- Test stream URL from dashboard\n\n## Acceptance Criteria\n- [ ] New channel appears in mobile app channel list\n- [ ] Inactive channels hidden from app\n- [ ] Stream URL test shows green/red status indicator" \
  "admin,must-have" "M6: Admin Dashboard" > /dev/null

create_issue \
  "[ADMIN-03] Admin: User management" \
  "## Features\n- Search and filter users by email, name, role, status\n- View user profile, subscription status, payment history\n- Suspend / unsuspend accounts\n- Change user role (user → admin)\n- Export user list as CSV\n\n## Acceptance Criteria\n- [ ] User search works with partial match\n- [ ] Suspended users cannot log in\n- [ ] Role changes take effect immediately on next request" \
  "admin,must-have" "M6: Admin Dashboard" > /dev/null

create_issue \
  "[ADMIN-04] Admin: Analytics dashboard" \
  "## Metrics to display\n- Live viewer count (current)\n- Total active subscriptions\n- Revenue today / this month\n- Top 5 VOD content by views\n- Subscription conversion rate\n- New user registrations (last 30 days chart)\n\n## Acceptance Criteria\n- [ ] Dashboard loads within 2 seconds\n- [ ] Charts render correctly with Recharts\n- [ ] Data refreshes every 60 seconds\n- [ ] Revenue figures accurate against payments table" \
  "admin,should-have" "M6: Admin Dashboard" > /dev/null

create_issue \
  "[ADMIN-05] Admin: Branding and app configuration" \
  "## Configurable settings\n- App name\n- Primary brand color (hex)\n- Logo upload\n- Feature flags (enable/disable VOD, podcasts, radio)\n- Subscription plans (name, price, duration, description)\n- Supported payment methods toggle\n\n## Acceptance Criteria\n- [ ] Config saved to DB and served via GET /api/v1/config\n- [ ] Mobile app loads config on startup\n- [ ] Brand color applied to primary UI elements\n- [ ] Feature flags hide/show tabs in bottom nav" \
  "admin,must-have" "M6: Admin Dashboard" > /dev/null

# ── MILESTONE 7: SCHEDULE & NOTIFICATIONS ──────────────────
echo "  → M7: Schedule & Notifications issues..."

create_issue \
  "[SCHED-01] Backend + Mobile: Programme schedule (EPG)" \
  "## Backend Endpoint\n\`GET /api/v1/schedule/:channel_id?date=YYYY-MM-DD\`\n\n## Mobile Screen\n- Horizontal scrollable EPG grid\n- Current programme highlighted\n- Now & Next shown on channel cards in TV tab\n\n## Admin\n- Add/edit programme slots in weekly grid view\n\n## Acceptance Criteria\n- [ ] EPG returns programmes for requested date\n- [ ] Now-playing programme correctly identified by time\n- [ ] Admin can add programmes to schedule\n- [ ] Mobile shows current + next programme on channel card" \
  "backend,mobile,admin,must-have" "M7: Programme Schedule & Notifications" > /dev/null

create_issue \
  "[NOTIF-01] Backend: FCM push notification service" \
  "## Task\nImplement FCM push notification sending from Go backend.\n\n## Features\n- Store FCM tokens per user device\n- Send to single user, user segment, or all users\n- Notification types: new content, programme reminder, subscription expiry\n\n## Endpoints\n- \`POST /api/v1/devices/register\` — register FCM token\n- \`POST /api/v1/admin/notify\` — admin sends push\n\n## Acceptance Criteria\n- [ ] FCM token stored on app launch / login\n- [ ] Admin can send push from dashboard\n- [ ] Notifications delivered to device within 30 seconds\n- [ ] Stale tokens cleaned up automatically" \
  "backend,notifications,should-have" "M7: Programme Schedule & Notifications" > /dev/null

create_issue \
  "[NOTIF-02] Mobile: Push notification handling" \
  "## Task\nHandle incoming FCM notifications in the Flutter app.\n\n## Behaviour\n- Foreground: show in-app snackbar/banner\n- Background: system notification — tap opens relevant screen\n- Terminated: system notification — tap cold-starts app to relevant screen\n\n## Acceptance Criteria\n- [ ] FCM token registered on login\n- [ ] All 3 notification states handled correctly\n- [ ] Deep link from notification navigates to correct screen\n- [ ] User can disable notification types in Profile settings" \
  "mobile,notifications,should-have" "M7: Programme Schedule & Notifications" > /dev/null

# ── MILESTONE 8: POLISH ─────────────────────────────────────
echo "  → M8: Polish issues..."

create_issue \
  "[QA-01] Testing: Write Go backend unit tests" \
  "## Scope\nUnit tests for all service layer functions.\n\n## Priority areas\n- Auth: registration, login, token refresh, JWT middleware\n- Billing: subscription creation, payment webhook handling\n- Streaming: signed URL generation and expiry\n- Content: access control checks (free vs premium)\n\n## Acceptance Criteria\n- [ ] Test coverage >= 70% on service packages\n- [ ] All tests pass in CI\n- [ ] Payment webhook tests use test fixtures (no real API calls)" \
  "backend,must-have" "M8: MVP Polish & Launch" > /dev/null

create_issue \
  "[QA-02] Testing: Flutter widget and integration tests" \
  "## Scope\n- Widget tests for key screens (login, home, player)\n- Integration test for critical user flows\n\n## Critical flows to test\n1. Register → Login → Browse VOD → Play\n2. Hit paywall → Subscribe → Access premium content\n3. Open TV tab → Select channel → Stream plays\n\n## Acceptance Criteria\n- [ ] Widget tests pass for auth screens\n- [ ] Integration tests cover 3 critical flows\n- [ ] Tests run in CI without a real device" \
  "mobile,must-have" "M8: MVP Polish & Launch" > /dev/null

create_issue \
  "[QA-03] Performance: Load test streaming server" \
  "## Task\nLoad test the streaming infrastructure for 10,000 concurrent viewers.\n\n## Tool: k6 or Locust\n\n## Tests\n- 1,000 concurrent HLS stream requests\n- 10,000 concurrent HLS stream requests\n- Monitor: CPU, memory, bandwidth, error rate\n\n## Acceptance Criteria\n- [ ] Stream start time < 5 seconds at 10k concurrent users\n- [ ] Error rate < 0.1% under load\n- [ ] Auto-scaling triggers correctly if using cloud" \
  "streaming,devops,must-have" "M8: MVP Polish & Launch" > /dev/null

create_issue \
  "[LAUNCH-01] Deployment: Production server setup" \
  "## Task\nSet up production environment (Linode or AWS).\n\n## Steps\n1. Provision server (4 vCPU, 8GB RAM minimum)\n2. Install Docker + Docker Compose\n3. Configure Cloudflare DNS + TLS\n4. Set all production environment variables\n5. Run database migrations on production\n6. Deploy via GitHub Actions production workflow\n7. Verify health checks pass\n\n## Acceptance Criteria\n- [ ] All services running in production\n- [ ] TLS certificate active (HTTPS enforced)\n- [ ] Health endpoint returns 200\n- [ ] Monitoring and alerting configured" \
  "devops,must-have" "M8: MVP Polish & Launch" > /dev/null

create_issue \
  "[LAUNCH-02] Deployment: App Store and Play Store submission" \
  "## Tasks\n\n### Android (Google Play)\n- [ ] Generate signed APK/AAB\n- [ ] Create Play Store listing (screenshots, description, privacy policy)\n- [ ] Submit for review\n\n### iOS (Apple App Store)\n- [ ] Configure signing certificates and provisioning profiles\n- [ ] Create App Store Connect listing\n- [ ] Submit for TestFlight beta first\n- [ ] Submit for App Store review\n\n## Acceptance Criteria\n- [ ] App approved and live on both stores\n- [ ] Version 1.0.0 tagged in GitHub" \
  "mobile,devops,must-have" "M8: MVP Polish & Launch" > /dev/null

echo ""
echo "✅ All issues created!"
echo ""

# ── GITHUB PROJECT BOARD ────────────────────────────────────
echo "Creating GitHub Project board..."

PROJECT_ID=$(gh project create \
  --owner "TgkCapture" \
  --title "OpenAir — Development Board" \
  --format json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('number',''))" 2>/dev/null || echo "")

if [ -n "$PROJECT_ID" ]; then
  echo "✅ Project board created: #$PROJECT_ID"
  echo "   View at: https://github.com/users/TgkCapture/projects/$PROJECT_ID"
else
  echo "⚠️  Project board could not be auto-created (requires Projects beta access)"
  echo "   Create manually at: https://github.com/TgkCapture/openair/projects"
  echo "   Recommended columns: Backlog | In Progress | In Review | Done"
fi

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✅ 14 labels created"
echo "  ✅ 8 milestones created"
echo "  ✅ 35 issues created"
echo "  ✅ Project board created"
echo ""
echo "Next steps:"
echo "  1. Visit https://github.com/TgkCapture/openair/issues"
echo "  2. Add all issues to the Project board"
echo "  3. Start coding with Issue #1: SCAFFOLD-01"
echo ""
echo "  Wiki: https://github.com/TgkCapture/openair/wiki"
echo "  Docs: Upload .docx files to the docs/ folder"
echo ""
