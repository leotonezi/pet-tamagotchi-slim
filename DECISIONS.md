# Architectural Decisions

Short records of non-obvious choices. Each entry answers: what was chosen, what was the alternative, and why.

---

## Auth

### JWT in localStorage, not httpOnly cookie

**Chose:** Store JWT in `localStorage`, send via `Authorization: Bearer` header.  
**Alternative:** `httpOnly` cookie with `credentials: true`.  
**Why:** The widget endpoint is cross-origin and embeddable on third-party pages. Cookie-based auth requires `SameSite=None; Secure` and CORS `credentials: true`, which forces explicit origin allowlisting and breaks the "embed anywhere" use case. `localStorage` + `Authorization` header sidesteps all of that at the cost of XSS exposure — acceptable here because the app has no payments or PII beyond email.

**Consequence:** CORS is configured with `credentials: false`. Never switch to cookies without revisiting CORS config.

---

### Devise + devise-api over custom JWT

**Chose:** `devise` + `devise-api` gem.  
**Alternative:** Hand-rolled JWT with `jwt` gem.  
**Why:** Devise handles password hashing, reset flow, validations. `devise-api` adds JWT token issuance on top. No reason to rebuild what's already battle-tested for a standard user/password flow.

---

## Serialization

### Blueprinter over ActiveModel::Serializer / Alba / jbuilder

**Chose:** Blueprinter.  
**Why:** Fast, explicit, no magic. Serializer output is defined in one place. No view-layer coupling (jbuilder). AMS has DSL complexity and N+1 footguns. Alba is faster but less common. Blueprinter is the sweet spot for a small API with predictable shapes.

**Rule:** Never `render json: model.as_json`. Always go through a blueprint.

---

## Background Jobs

### Solid Queue, in-process, no Redis

**Chose:** Solid Queue (Rails 8 built-in), runs in the same process as the API.  
**Alternative:** Sidekiq + Redis.  
**Why:** Low traffic app. Solid Queue uses Postgres (already present) as the queue backend — zero additional infrastructure. `PetDecayJob` runs every 15 minutes on a small dataset; there is no throughput case for Redis.

**Consequence:** If traffic grows, switching to Sidekiq is a Gemfile + config change, no schema migration needed.

---

## Frontend State

### React Query for server state, no global store

**Chose:** `@tanstack/react-query` for all API-fetched data.  
**Alternative:** Redux Toolkit, Zustand, Context + useReducer.  
**Why:** All state in this app is server-derived. React Query handles caching, invalidation, loading/error states, and refetching automatically. Adding Redux/Zustand would be premature abstraction for a CRUD app with no complex client-side state machine.

**Rule:** `AuthContext` and `PetContext` in React Context are fine for identity and active-pet selection (not frequently changing). API data lives in React Query cache, nowhere else.

---

## API Design

### Single error shape everywhere

**Chose:** `{ "error": "..." }` for all error responses.  
**Why:** Frontend can write one error handler. One `rescue_from` block in `ApplicationController` covers every controller. Consistent shape means no per-route error parsing.

**Rule:** Never return a different error shape from any endpoint.

---

### Namespace all routes under `/api/v1/`

**Chose:** Full versioning from day one.  
**Why:** Widget embeds are long-lived. If the API contract needs a breaking change, `/api/v2/` can coexist. Cost is ~zero upfront; benefit is avoiding forced upgrades for embedded widgets.

---

## Database

### Smallint for stat columns

**Chose:** `smallint` (2 bytes, range −32768 to 32767) for all stat columns.  
**Why:** Stats are clamped to 0–100. `smallint` is sufficient and uses half the space of `integer`. Matters at scale for a table updated by a background job every 15 minutes across all living pets.

---

### is_alive boolean instead of soft-delete / status enum

**Chose:** `is_alive boolean`.  
**Alternative:** `status enum` with values like `alive`, `dead`, `hibernating`.  
**Why:** The game currently has two states. A boolean is the simplest correct model. If a third state is needed, a migration to an enum is straightforward and does not break existing queries on `is_alive = true`.

---

## Widget

### Web Component over iframe-only

**Chose:** Compile `PetWidget.tsx` to a Web Component via `@r2wc/react-to-web-component`, with an iframe fallback at `/embed/:pet_id`.  
**Why:** Web Components integrate into any page without a frame boundary — style leakage is opt-in via CSS custom properties. iFrame is simpler but imposes height/scroll constraints that make embedding awkward.

**Consequence:** Web Component builds must be self-contained (inlined CSS). Never import external fonts or CDN assets in the widget bundle.

---

## Testing

### Real database, no ActiveRecord mocking

**Chose:** RSpec with real Postgres test database, `use_transactional_fixtures = true`.  
**Why:** Mocked AR leads to tests that pass in CI but fail against real DB behavior (e.g., constraint violations, type coercions, `with_lock` behavior). Transactional fixtures reset state between examples without truncation overhead.

**Rule:** Do not mock `Pet`, `User`, or any AR model. Use FactoryBot to build real records.

---

## Deployment

### Railway (API) + Vercel (web) over a single host

**Chose:** Separate platforms per sub-project.  
**Why:** Each platform has zero-config deploy for its target (Railway for Rails/Postgres, Vercel for static Vite builds). A single VPS would require Nginx config, SSL, process management — complexity with no benefit at this scale.

**Consequence:** CORS config matters from day one. `FRONTEND_URL` env var must be set correctly in Railway.
