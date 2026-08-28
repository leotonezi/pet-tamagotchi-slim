# Pet Tamagotchi — Web2 Implementation Plan

Ruby on Rails API + React frontend. Feature-complete port of the on-chain game.

---

## Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Backend | Ruby on Rails 8 (API mode) | Fast CRUD, ActiveRecord, built-in jobs |
| Database | PostgreSQL | JSON support, reliable |
| Background jobs | Solid Queue (Rails 8 built-in) | Stat decay, no Redis required |
| Auth | Devise + devise-api (JWT) | Battle-tested, fast to ship |
| Frontend | React + TypeScript + Vite + Tailwind | Mirrors current app stack |
| HTTP client | Axios | Simple, interceptors for JWT |
| Widget | React Web Component (via `@r2wc/react-to-web-component`) | Embeddable anywhere |
| Deployment | Railway (API) + Vercel (frontend) | Zero-config, free tier |

---

## Repository Structure

```
pet-tamagotchi-web/
├── api/                    # Rails app (API mode)
│   ├── app/
│   │   ├── controllers/api/v1/
│   │   ├── models/
│   │   ├── jobs/           # Solid Queue jobs
│   │   ├── services/       # PetCareService, BreedService, RewardService
│   │   └── serializers/    # ActiveModel::Serializer or Blueprinter
│   ├── config/
│   ├── db/
│   │   ├── migrate/
│   │   └── seeds.rb        # Item catalog seed
│   └── spec/               # RSpec
├── web/                    # React app
│   ├── src/
│   │   ├── api/            # Axios client + endpoint modules
│   │   ├── components/
│   │   ├── contexts/       # AuthContext, PetContext
│   │   ├── hooks/
│   │   ├── pages/
│   │   └── widget/         # Embeddable web component
│   └── package.json
└── docker-compose.yml      # Postgres for local dev
```

---

## Database Schema

```sql
-- Users (auth)
users
  id              bigserial PK
  email           varchar UNIQUE NOT NULL
  created_at      timestamp
  updated_at      timestamp
  -- Devise columns: encrypted_password, reset_password_token, etc.

-- Virtual currency
users.coins       integer NOT NULL DEFAULT 0

-- Pets
pets
  id              bigserial PK
  user_id         bigint FK users.id NOT NULL
  name            varchar(32) NOT NULL
  species         varchar(16) NOT NULL
  hunger          smallint NOT NULL DEFAULT 30      -- 0-100, 0=satisfied
  tiredness       smallint NOT NULL DEFAULT 20      -- 0-100, 0=rested
  hygiene         smallint NOT NULL DEFAULT 80      -- 0-100, 100=pristine
  happiness       smallint NOT NULL DEFAULT 70      -- 0-100
  health          smallint NOT NULL DEFAULT 75      -- derived
  needs_meal      boolean NOT NULL DEFAULT false
  needs_walk      boolean NOT NULL DEFAULT false
  needs_bath      boolean NOT NULL DEFAULT false
  is_alive        boolean NOT NULL DEFAULT true
  birth_date      timestamp NOT NULL DEFAULT NOW()
  last_interaction timestamp NOT NULL DEFAULT NOW()
  created_at      timestamp
  updated_at      timestamp
  UNIQUE(user_id, name)

-- Inventory (one per user)
inventories
  id      bigserial PK
  user_id bigint FK users.id NOT NULL UNIQUE
  created_at timestamp
  updated_at timestamp

inventory_slots
  id           bigserial PK
  inventory_id bigint FK inventories.id NOT NULL
  item_id      smallint NOT NULL
  qty          smallint NOT NULL DEFAULT 0
  UNIQUE(inventory_id, item_id)

-- Item catalog (seeded, not user data)
items
  id              bigserial PK
  name            varchar NOT NULL
  description     text
  price_coins     integer NOT NULL
  hunger_delta    smallint NOT NULL DEFAULT 0
  hygiene_delta   smallint NOT NULL DEFAULT 0
  happiness_delta smallint NOT NULL DEFAULT 0
  tiredness_delta smallint NOT NULL DEFAULT 0

-- Daily reward claim tracking
claim_states
  id            bigserial PK
  user_id       bigint FK users.id NOT NULL
  pet_id        bigint FK pets.id NOT NULL
  last_claim_at timestamp
  total_claims  integer NOT NULL DEFAULT 0
  UNIQUE(user_id, pet_id)

-- Breeding log
breed_records
  id          bigserial PK
  owner_id    bigint FK users.id NOT NULL
  parent_a_id bigint FK pets.id NOT NULL
  parent_b_id bigint FK pets.id NOT NULL
  offspring_id bigint FK pets.id NOT NULL
  created_at  timestamp
```

---

## Game Mechanics (ported from Rust)

All logic lives in `app/services/pet_mechanics.rb` — single source of truth.

### Stat Decay (per elapsed hour)

```
hunger    += 1 per 4 hours    (floor division)
tiredness -= 1 per 4 hours    (natural rest)
hygiene   -= 1 per 6 hours
```

All stats clamp to [0, 100].

### Death Conditions

```
hunger   > 95  → is_alive = false
hygiene  < 10  → is_alive = false
happiness < 5  → is_alive = false
```

### Health Formula

```
health = ((100 - hunger) + (100 - tiredness) + hygiene + happiness) / 4
```

### Needs Flags

```
needs_meal = hunger   > 70
needs_walk = happiness < 60
needs_bath = hygiene   < 40
```

### Care Action Stat Deltas

| Action | hunger | tiredness | hygiene | happiness |
|--------|--------|-----------|---------|-----------|
| feed   | -25    | —         | —       | +5        |
| walk   | +5     | +10       | -5      | +15       |
| bathe  | —      | —         | +50     | +5        |
| sleep  | +5     | -50       | —       | —         |
| play   | +5     | +10       | —       | +20       |

Each action: apply_time_decay first → apply delta → refresh_needs_and_health → save.

### Item Catalog (seed data)

| id | name   | hunger | hygiene | happiness | tiredness | price |
|----|--------|--------|---------|-----------|-----------|-------|
| 1  | Apple  | -30    | 0       | +5        | 0         | 10    |
| 2  | Soap   | 0      | +60     | 0         | 0         | 10    |
| 3  | Toy    | 0      | 0       | +30       | +10       | 10    |
| 4  | Pillow | +5     | 0       | 0         | -60       | 10    |

### Breeding

1. Both parents must be alive and owned by same user.
2. Parents must be different pets.
3. Random bit per stat selects which parent contributes it (use `SecureRandom`).
4. Species: first half of parent A species + second half of parent B species, truncated to 16 chars.
5. Offspring starts with inherited stats; `refresh_needs_and_health` applied immediately.

### Daily Rewards

- Cooldown: 24 hours from last claim per pet.
- Base: 10 coins.
- +5 coins if happiness ≥ 80.
- +5 coins if health ≥ 80.
- +5 coins if hunger ≤ 20 AND hygiene ≥ 80 (perfect care bonus).
- Max per claim: 25 coins.

---

## API Endpoints

All routes under `/api/v1/`. Auth via `Authorization: Bearer <jwt>`.

### Auth
```
POST   /auth/sign_up          { email, password }
POST   /auth/sign_in          { email, password } → { token, user }
DELETE /auth/sign_out
GET    /auth/me               → current user
```

### Pets
```
GET    /pets                  → list user's pets
POST   /pets                  { name, species }
GET    /pets/:id              → pet detail (triggers apply_time_decay)
DELETE /pets/:id
POST   /pets/:id/feed
POST   /pets/:id/walk
POST   /pets/:id/bathe
POST   /pets/:id/sleep
POST   /pets/:id/play
POST   /pets/:id/check_status → apply_time_decay, return current state
```

### Breeding
```
POST   /breed                 { parent_a_id, parent_b_id, offspring_name }
```

### Shop & Inventory
```
GET    /items                 → item catalog
GET    /inventory             → user's inventory
POST   /inventory/buy         { item_id, qty }
POST   /inventory/use         { item_id, pet_id }
```

### Rewards
```
GET    /rewards/:pet_id       → claim state + eligibility
POST   /rewards/:pet_id/claim → award coins, update claim_state
```

### Widget (public, no auth)
```
GET    /widget/:pet_id        → public pet snapshot (read-only)
```

---

## Implementation Phases

### Phase 1 — Bootstrap

- [ ] `rails new api --api --database=postgresql`
- [ ] Add gems: `devise`, `devise-api`, `rack-cors`, `blueprinter` (or `alba`), `rspec-rails`, `factory_bot_rails`
- [ ] Configure CORS to allow frontend origin
- [ ] `docker-compose.yml` with postgres service
- [ ] `Vite + React + TypeScript + Tailwind` in `web/`
- [ ] Axios client with JWT interceptor in `web/src/api/client.ts`
- [ ] Health check endpoint `GET /up`

### Phase 2 — Auth

- [ ] Devise User model + `devise-api` token auth
- [ ] Auth controller: sign_up, sign_in, sign_out, me
- [ ] React: AuthContext, login/register pages, protected routes
- [ ] Store JWT in `httpOnly` cookie or `localStorage` (choose one, stay consistent)

### Phase 3 — Core Pet

- [ ] `Pet` model + migration
- [ ] `PetMechanics` service module (stat logic, health formula, death check)
- [ ] Pets controller (CRUD)
- [ ] Background job `PetDecayJob` — runs every 15 min via Solid Queue recurring, calls `apply_time_decay` + `save` on all living pets
- [ ] React: PetListPage, PetDetailPage (port from `app/src/pages/`)

### Phase 4 — Care Actions

- [ ] `PetActionsController` — feed, walk, bathe, sleep, play, check_status
- [ ] Each action: find pet → verify alive + ownership → apply_time_decay → delta → refresh → save → render
- [ ] React: care buttons on PetDetailPage with optimistic updates

### Phase 5 — Inventory & Shop

- [ ] `Item` model, seed the 4 items
- [ ] `Inventory` + `InventorySlot` models, auto-created on user creation
- [ ] `ShopController#buy` — deduct coins, add to inventory slot
- [ ] `InventoryController#use` — apply item deltas to pet, decrement slot qty
- [ ] React: ShopPage, inventory panel on PetDetailPage

### Phase 6 — Breeding

- [ ] `BreedService` — validates parents, generates offspring stats, blends species
- [ ] `BreedController` — wraps BreedService in transaction, creates offspring pet + breed_record
- [ ] React: breed UI on PetListPage (select two pets)

### Phase 7 — Rewards

- [ ] `ClaimState` model
- [ ] `RewardService` — cooldown check, coin calculation, award
- [ ] `RewardsController` — show eligibility + claim
- [ ] React: RewardsPage (port from `app/src/pages/RewardsPage.tsx`)

### Phase 8 — Widget

- [ ] `WidgetController#show` — public, no auth, returns pet snapshot JSON
- [ ] React `web/src/widget/PetWidget.tsx` — minimal pet card (name, species, stats bars, status)
- [ ] Compile as Web Component via `@r2wc/react-to-web-component`
- [ ] Publish embed snippet: `<script src="..."></script><pet-widget pet-id="123"></pet-widget>`
- [ ] iFrame fallback: `/embed/:pet_id` route serving the widget page standalone

### Phase 9 — Polish & Deploy

- [ ] Rate limiting (Rack::Attack) on care actions and claims
- [ ] Request validation with strong params + model validations
- [ ] Error serializer (consistent `{ error: "..." }` shape)
- [ ] RSpec: model specs, request specs for all endpoints
- [ ] Railway: deploy `api/`, provision Postgres, set ENV
- [ ] Vercel: deploy `web/`, set `VITE_API_URL`
- [ ] Configure Solid Queue recurring job in `config/recurring.yml`

---

## Testing Strategy

- **Model specs** — PetMechanics service unit tests (stat deltas, clamping, death conditions)
- **Request specs** — all endpoints, auth required, ownership enforcement
- **Factory Bot** — user, pet, inventory factories with trait overrides
- **No mocking DB** — use real test database, reset between specs

---

## ENV Variables

### API (`api/.env`)
```
DATABASE_URL=postgresql://...
DEVISE_JWT_SECRET_KEY=...
FRONTEND_URL=http://localhost:5173
RAILS_ENV=development
```

### Web (`web/.env`)
```
VITE_API_URL=http://localhost:3000
```

---

## Widget Embed Example

```html
<!-- Add once per page -->
<script src="https://your-cdn.com/pet-widget.js"></script>

<!-- Drop anywhere -->
<pet-widget pet-id="42"></pet-widget>
```

Widget is read-only, no auth, shows: species emoji, name, stat bars (hunger/hygiene/happiness/tiredness/health), alive/dead status.
