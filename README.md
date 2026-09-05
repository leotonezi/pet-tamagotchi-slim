# Pet Tamagotchi Slim

Web2 port of a blockchain tamagotchi game. Same mechanics, no wallet required.

Ruby on Rails 8 API + React/TypeScript/Vite frontend.

---

## Features

- **Pets** — create, care for, and watch stats decay in real time
- **Care actions** — Feed (15 min), Walk (30 min), Bathe (10 min), Sleep (4h/8h), Play (1h/2h/4h)
- **Stat decay** — hunger/tiredness every 5 min, hygiene every 10 min via background job
- **Health & death** — health derived from all stats; pet dies if hunger > 95, hygiene < 10, or happiness < 5
- **Shop & inventory** — buy items with coins (Apple, Soap, Toy, Pillow), use on pets
- **Breeding** — combine two alive pets to produce offspring with blended stats and species
- **Daily rewards** — claim 10–25 coins once per 24 hours with live countdown

---

## Stack

| Layer | Choice |
|---|---|
| API | Ruby on Rails 8 (API mode) |
| Database | PostgreSQL |
| Background jobs | Solid Queue (stat decay every 15 min) |
| Auth | Devise + devise-api (JWT, `Authorization: Bearer`) |
| Serialization | Blueprinter |
| Frontend | React + TypeScript + Vite + Tailwind v4 |
| State | React Query (`@tanstack/react-query`) |
| HTTP client | Axios |

---

## Monorepo Layout

```
api/    → Rails app (API mode)
web/    → React + Vite app
docker-compose.yml  → PostgreSQL for local dev
```

---

## Local Development

### Prerequisites

- Ruby 3.3.6 (via rbenv)
- Node 20+
- Docker (for Postgres)

### 1. Start Postgres

```bash
docker-compose up -d
```

### 2. Rails API

```bash
cd api
bundle install
cp .env.example .env          # set DEVISE_JWT_SECRET_KEY
bundle exec rails db:create db:migrate db:seed
bundle exec rails s -p 3000
```

### 3. React frontend

```bash
cd web
npm install
cp .env.example .env          # set VITE_API_URL=http://localhost:3000
npm run dev
```

Frontend runs at `http://localhost:5173`.

---

## Environment Variables

### `api/.env`

```
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/pet_tamagotchi_development
DEVISE_JWT_SECRET_KEY=your_secret_here
FRONTEND_URL=http://localhost:5173
RAILS_ENV=development
```

### `web/.env`

```
VITE_API_URL=http://localhost:3000
```

---

## API Overview

All routes under `/api/v1/`. Auth via `Authorization: Bearer <token>`.

| Method | Path | Description |
|---|---|---|
| POST | `/auth/sign_up` | Register |
| POST | `/auth/sign_in` | Login → JWT |
| DELETE | `/auth/sign_out` | Revoke token |
| GET | `/auth/me` | Current user |
| GET | `/pets` | List user's pets |
| POST | `/pets` | Create pet |
| GET | `/pets/:id` | Pet detail (triggers stat check) |
| DELETE | `/pets/:id` | Delete pet |
| POST | `/pets/:id/feed` | Feed (15 min action) |
| POST | `/pets/:id/walk` | Walk (30 min action) |
| POST | `/pets/:id/bathe` | Bathe (10 min action) |
| POST | `/pets/:id/sleep` | Sleep (`hours`: 4 or 8) |
| POST | `/pets/:id/play` | Play (`hours`: 1, 2, or 4) |
| GET | `/items` | Shop catalog |
| GET | `/inventory` | User's inventory |
| POST | `/inventory/buy` | Buy item |
| POST | `/inventory/use` | Use item on pet |
| POST | `/breed` | Breed two pets |
| GET | `/rewards` | Reward eligibility + countdown |
| POST | `/rewards/claim` | Claim daily reward |

All errors return `{ "error": "Human-readable message" }`.

---

## Game Mechanics

### Stat decay (per background tick, every 15 min)

| Stat | Rate |
|---|---|
| Hunger | +1 per 5 min |
| Tiredness | −1 per 5 min |
| Hygiene | −1 per 10 min |

### Health formula

```
health = ((100 − hunger) + (100 − tiredness) + hygiene + happiness) / 4
```

### Death conditions

- `hunger > 95`
- `hygiene < 10`
- `happiness < 5`

### Need flags

| Flag | Condition |
|---|---|
| `needs_meal` | hunger > 70 |
| `needs_walk` | happiness < 60 |
| `needs_bath` | hygiene < 40 |

---

## Testing

```bash
# API (RSpec)
cd api && bundle exec rspec

# Frontend (Vitest)
cd web && npm run test
```

---

## Deployment

- **API** → [Railway](https://railway.app). Set `DATABASE_URL`, `DEVISE_JWT_SECRET_KEY`, `FRONTEND_URL`, `RAILS_ENV=production`.
- **Frontend** → [Vercel](https://vercel.com). Set `VITE_API_URL` to your Railway API URL.
- Solid Queue runs in-process on Railway — no separate worker needed.
