# Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Browser / Embedder                                             │
│                                                                 │
│  ┌───────────────────┐      ┌─────────────────────────────┐    │
│  │  React SPA        │      │  <pet-widget> Web Component │    │
│  │  (Vite + TS)      │      │  (standalone embed)         │    │
│  │  localhost:5173   │      │  no auth required           │    │
│  └────────┬──────────┘      └──────────────┬──────────────┘    │
│           │ JWT Bearer                      │ no auth           │
└───────────┼─────────────────────────────────┼───────────────────┘
            │                                 │
            ▼                                 ▼
┌───────────────────────────────────────────────────────────────┐
│  Rails 8 API  (API mode, port 3000)                           │
│                                                               │
│  Routes: /api/v1/**  +  /up  +  /api/v1/widget/:id           │
│                                                               │
│  ┌────────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Controllers   │  │  Services    │  │  Jobs            │  │
│  │  api/v1/       │─▶│  PetMechan.  │  │  PetDecayJob     │  │
│  │  thin layer    │  │  BreedSvc    │  │  (Solid Queue)   │  │
│  │  auth + route  │  │  RewardSvc   │  │  every 15 min    │  │
│  └────────────────┘  └──────────────┘  └──────────────────┘  │
│                                                               │
│  ┌────────────────┐  ┌──────────────┐                        │
│  │  Blueprinter   │  │  Devise API  │                        │
│  │  serializers   │  │  JWT tokens  │                        │
│  └────────────────┘  └──────────────┘                        │
└───────────────────────────────────┬───────────────────────────┘
                                    │ ActiveRecord
                                    ▼
                        ┌───────────────────────┐
                        │  PostgreSQL            │
                        │  (Docker locally,      │
                        │   Railway in prod)     │
                        └───────────────────────┘
```

## Sub-projects

| Directory | What it is |
|-----------|-----------|
| `api/` | Rails 8 app, API mode. Serves JSON only. Handles all business logic, auth, and background jobs. |
| `web/` | React + TypeScript SPA. Talks to `api/` via Axios over HTTP. |
| `web/src/widget/` | Embeddable Web Component compiled to a standalone JS bundle. Read-only pet snapshot, no auth. |
| `docker-compose.yml` | Postgres 16 for local development. |

## Request Lifecycle

### Authenticated request

```
Browser
  → HTTP request + Authorization: Bearer <jwt>
  → Rails router
  → ApplicationController#authenticate_devise_api_token!
  → Controller#action (thin: validates params, calls service)
  → Service (business logic, DB mutations with with_lock)
  → Blueprint#render (serializes AR model to JSON)
  → HTTP response
```

### Care action (feed / walk / bathe / sleep / play)

```
Controller receives POST /api/v1/pets/:id/feed
  1. authenticate_devise_api_token!
  2. @pet = current_devise_api_user.pets.find(params[:id])   ← ownership enforced here
  3. PetMechanics.feed(@pet)
       a. pet.with_lock { ... }                              ← prevents concurrent corruption
       b. apply_time_decay(pet)                              ← catch up elapsed hours first
       c. apply stat deltas
       d. refresh_needs_and_health(pet)
       e. pet.last_interaction = Time.current
       f. pet.save!
  4. render PetBlueprint.render(@pet)
```

### Background decay

```
Solid Queue recurring trigger (every 15 min)
  → PetDecayJob#perform
  → Pet.where(is_alive: true).find_each
  → PetMechanics.apply_time_decay(pet)
  → pet.save! if pet.changed?
```

## Layers

### Controllers (`app/controllers/api/v1/`)

- Authenticate, authorize, parse params, call one service, render blueprint.
- No business logic. No direct stat math.
- All queries scoped through `current_devise_api_user`.

### Services (`app/services/`)

- Pure Ruby modules. No HTTP, no controller concerns.
- Return `Result` struct (`success?`, `error`) — never raise for expected failures.
- All stat mutations use `with_lock`.

| Service | Responsibility |
|---------|---------------|
| `PetMechanics` | Stat decay, care action deltas, health formula, death check, needs flags |
| `BreedService` | Parent validation, stat inheritance, species blending, offspring creation |
| `RewardService` | Cooldown check, coin calculation, coin award |

### Serializers (`app/serializers/` — Blueprinter)

- One blueprint per model.
- Never use `model.as_json` or `render json: model` directly.

### Jobs (`app/jobs/`)

- `PetDecayJob` — only job in Phase 1–3. Configured in `config/recurring.yml`.

## Auth

Devise + devise-api. JWT in `Authorization: Bearer` header. Token stored in browser `localStorage`.

- Sign up → POST `/api/v1/auth/sign_up`
- Sign in → POST `/api/v1/auth/sign_in` → returns JWT
- All protected routes call `authenticate_devise_api_token!` before action

Widget endpoint (`/api/v1/widget/:id`) is public — no auth, read-only, no mutations.

## Error Shape

All errors, everywhere:

```json
{ "error": "Human-readable message" }
```

HTTP status codes:

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 401 | Not authenticated |
| 403 | Authenticated but wrong owner |
| 404 | Resource not found |
| 422 | Validation failure / business rule violation |

Centralized in `ApplicationController` via `rescue_from`.

## Frontend Structure

```
web/src/
  api/
    client.ts       ← single Axios instance, JWT interceptor
    pets.ts         ← pet endpoint functions
    auth.ts
    shop.ts
    rewards.ts
  components/
    layout/
    pet/
    shop/
    shared/
  contexts/
    AuthContext.tsx  ← current user + JWT
    PetContext.tsx   ← active pet state
  hooks/
    usePet.ts       ← React Query wrapper
    useAuth.ts
  pages/
    HomePage.tsx
    PetListPage.tsx
    PetDetailPage.tsx
    ShopPage.tsx
    RewardsPage.tsx
  widget/
    PetWidget.tsx   ← embeddable component
    widget-entry.ts ← Web Component wrapper
```

Server state managed by React Query (`@tanstack/react-query`). No Redux, no Zustand.

## Deployment

| Piece | Platform | Notes |
|-------|----------|-------|
| `api/` | Railway | Provisions Postgres, runs Solid Queue in-process |
| `web/` | Vercel | Static build, `VITE_API_URL` points to Railway |
| Widget JS | Vercel / CDN | Standalone bundle from `web/src/widget/` |
