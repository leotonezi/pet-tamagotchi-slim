# Pet Tamagotchi Web2 — Claude Instructions

## Project Overview

Web2 port of pet-tamagotchi. Ruby on Rails 8 API (API mode) + React/TypeScript frontend.
No blockchain. Same game mechanics as the on-chain version, ported to a standard web stack.

See `IMPLEMENTATION.md` for full spec, DB schema, game rules, and API contract.

## Monorepo Layout

```
api/    → Rails app
web/    → React + Vite + Tailwind app
```

Always clarify which sub-project a task targets before touching files.

---

## RTK — Token-Optimized Commands

Always prefix commands with `rtk`. Always, including in `&&` chains.

```bash
# Rails
rtk bundle exec rails test        # test failures only
rtk bundle exec rails db:migrate  # compact output
rtk cargo check                   # (not used here)

# Rspec
rtk rspec                         # failures only (60% savings)
rtk rspec spec/models/            # scoped run

# Frontend
rtk tsc                           # TypeScript errors only
rtk lint                          # ESLint violations only
rtk vitest                        # test failures only

# Git
rtk git status
rtk git diff
rtk git log
rtk git add <files> && rtk git commit -m "..."
```

---

## Rails Conventions

### File structure
```
app/
  controllers/api/v1/   # all controllers namespaced
  models/               # ActiveRecord models
  services/             # PetMechanics, BreedService, RewardService — pure Ruby, no HTTP
  serializers/          # Blueprinter blueprints (not ActiveModel::Serializer)
  jobs/                 # Solid Queue jobs
```

### Controller pattern

Keep controllers thin. Business logic belongs in services.

```ruby
class Api::V1::PetsController < ApplicationController
  before_action :authenticate_devise_api_token!
  before_action :set_pet, only: [:show, :feed, :walk, ...]

  def feed
    result = PetMechanics.feed(@pet)
    if result.success?
      render json: PetBlueprint.render(@pet)
    else
      render json: { error: result.error }, status: :unprocessable_entity
    end
  end

  private

  def set_pet
    @pet = current_devise_api_user.pets.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Not found' }, status: :not_found
  end
end
```

Always scope DB queries through `current_devise_api_user` — never fetch by bare ID.

### Service pattern

Services return a result object, never raise for expected failures.

```ruby
# app/services/pet_mechanics.rb
module PetMechanics
  Result = Struct.new(:success?, :error, keyword_init: true)

  def self.feed(pet)
    pet.with_lock do
      apply_time_decay(pet)
      pet.hunger    = clamp(pet.hunger - 25)
      pet.happiness = clamp(pet.happiness + 5)
      refresh_needs_and_health(pet)
      pet.last_interaction = Time.current
      pet.save!
    end
    Result.new(success?: true)
  rescue => e
    Result.new(success?: false, error: e.message)
  end
end
```

Use `with_lock` on all care actions to prevent concurrent stat corruption.

### Game mechanics module

All stat logic lives in `PetMechanics`. No exceptions. Never compute stats in controllers or models.

Key rules (exact, match Rust source):
- `health = ((100 - hunger) + (100 - tiredness) + hygiene + happiness) / 4`
- `needs_meal = hunger > 70`
- `needs_walk = happiness < 60`
- `needs_bath = hygiene < 40`
- Death: `hunger > 95 || hygiene < 10 || happiness < 5`
- Decay per elapsed hour: hunger +1/4h, tiredness -1/4h, hygiene -1/6h
- All stats clamp to 0..100

### Migrations

- Always include `null: false` and defaults on stat columns.
- Never change existing migrations — always add new ones.
- Run `rtk bundle exec rails db:migrate` after creating.

### Serializers (Blueprinter)

```ruby
class PetBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :species, :hunger, :tiredness, :hygiene, :happiness,
         :health, :needs_meal, :needs_walk, :needs_bath, :is_alive,
         :birth_date, :last_interaction
end
```

Always use blueprints — never `render json: model.as_json`.

### Background Jobs (Solid Queue)

```ruby
# app/jobs/pet_decay_job.rb
class PetDecayJob < ApplicationJob
  queue_as :default

  def perform
    Pet.where(is_alive: true).find_each do |pet|
      PetMechanics.apply_time_decay(pet)
      pet.save! if pet.changed?
    end
  end
end
```

Configured as recurring in `config/recurring.yml` (every 15 minutes). Do not use `sleep` or manual scheduling.

---

## React/Frontend Conventions

### Structure
```
src/
  api/
    client.ts         # Axios instance with JWT interceptor
    pets.ts           # pet endpoint functions
    auth.ts
    shop.ts
    rewards.ts
  components/
    layout/
    pet/
    shop/
    shared/
  contexts/
    AuthContext.tsx    # current user + JWT
    PetContext.tsx     # active pet state
  hooks/
    usePet.ts
    useAuth.ts
  pages/
    HomePage.tsx
    PetListPage.tsx
    PetDetailPage.tsx
    ShopPage.tsx
    RewardsPage.tsx
  widget/
    PetWidget.tsx     # embeddable component
    widget-entry.ts   # web component wrapper
```

### API client pattern

```typescript
// src/api/client.ts
import axios from 'axios';

const client = axios.create({ baseURL: import.meta.env.VITE_API_URL });

client.interceptors.request.use(config => {
  const token = localStorage.getItem('jwt');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default client;
```

All endpoint modules import from `client.ts` — never create new Axios instances.

### State management

Use React Query (`@tanstack/react-query`) for server state. No Redux, no Zustand for API data.

```typescript
// hooks/usePet.ts
export function usePet(id: number) {
  return useQuery({
    queryKey: ['pet', id],
    queryFn: () => api.pets.get(id),
  });
}
```

### No over-abstraction

Three similar API calls → three functions, not a factory. Only abstract when there are 4+ repeated patterns with identical shape.

### TypeScript

Strict mode on. No `any`. Derive types from API response shapes using `z.infer` (Zod) or plain interfaces — choose one approach and stay consistent.

---

## Testing

### Rails (RSpec)

```
spec/
  models/        # PetMechanics unit tests — all game logic branches
  requests/      # API endpoint tests — auth, ownership, stat changes
  factories/     # FactoryBot definitions
  support/       # shared contexts (authenticated requests)
```

- Always test ownership: another user cannot access/modify a pet they don't own.
- Always test death conditions: pet cannot be acted on when `is_alive = false`.
- Always test stat clamping: no stat goes below 0 or above 100.
- Use real database — no mocking ActiveRecord.

### Frontend (Vitest + React Testing Library)

- Test PetMechanics display logic (stat bar widths, status badges).
- Test auth redirect (protected routes redirect to login).
- Mock API calls with MSW.

---

## Security Checklist

Before any PR:
- [ ] All pet routes scoped through `current_devise_api_user.pets`
- [ ] `with_lock` on all stat-mutating actions
- [ ] Strong params on all write endpoints
- [ ] CORS restricted to known frontend origins only
- [ ] Rack::Attack limits on: `/api/v1/pets/:id/feed` etc. (10 req/min per user)
- [ ] Widget endpoint `/api/v1/widget/:id` is read-only, no auth, no mutation

---

## Common Commands

```bash
# Start local dev
docker-compose up -d                    # start postgres
cd api && bundle exec rails s -p 3000   # Rails API
cd web && npm run dev                   # Vite dev server

# Database
rtk bundle exec rails db:create db:migrate db:seed

# Tests
rtk rspec                               # all specs
rtk rspec spec/models/pet_mechanics_spec.rb  # specific file
rtk vitest                              # frontend tests

# Generate
rails generate model Pet name:string user:references
rails generate migration AddCoinsToUsers coins:integer

# Lint
rtk lint                               # ESLint
rtk bundle exec rubocop                # Ruby style
```

---

## Error Response Shape

All errors return consistent JSON:

```json
{ "error": "Human-readable message" }
```

All success responses return the resource or `{ "message": "..." }` for actions with no meaningful return value.

HTTP status codes:
- `200` — success
- `201` — created
- `401` — not authenticated
- `403` — wrong owner (authenticated but not your resource)
- `404` — not found
- `422` — validation failure / business rule violation (pet dead, cooldown active, etc.)

---

## Deployment

- **API**: Railway. Set `DATABASE_URL`, `DEVISE_JWT_SECRET_KEY`, `RAILS_ENV=production`, `FRONTEND_URL`.
- **Web**: Vercel. Set `VITE_API_URL` to Railway API URL.
- **Jobs**: Solid Queue runs in-process on Railway (no separate worker needed for low traffic).
- **Widget CDN**: build `web/src/widget` to a standalone bundle, host on Vercel or CDN.

---

## Agent Hints

When planning a feature: read `IMPLEMENTATION.md` first — spec, schema, and API contract are already defined there. Do not redesign what's already specced.

When adding a care action: always follow the pattern in `PetMechanics` — apply_time_decay → stat delta → refresh_needs_and_health → save with lock.

When adding an endpoint: scope to current user, use blueprint for rendering, return consistent error shape.
