# Database

PostgreSQL 16. All tables use `bigserial` primary keys and `created_at`/`updated_at` timestamps unless noted.

---

## users

Stores registered players. Managed by Devise — most auth columns (encrypted password, reset tokens, etc.) are added automatically by the Devise generator and not listed here.

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigserial PK | |
| `email` | varchar UNIQUE NOT NULL | Login identifier |
| `coins` | integer NOT NULL DEFAULT 0 | Virtual currency, earned via daily rewards |
| `encrypted_password` | varchar | Devise-managed |
| `created_at` / `updated_at` | timestamp | |

A user can own many pets and has exactly one inventory.

---

## pets

One row per pet. Tracks all live game state — stats decay over time via background job.

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigserial PK | |
| `user_id` | bigint FK → users | Owner. All queries must be scoped through this. |
| `name` | varchar(32) NOT NULL | Unique per user (enforced by DB constraint) |
| `species` | varchar(16) NOT NULL | Free text; blended during breeding |
| `hunger` | smallint NOT NULL DEFAULT 30 | 0–100. **0 = full, 100 = starving.** High is bad. |
| `tiredness` | smallint NOT NULL DEFAULT 20 | 0–100. **0 = rested, 100 = exhausted.** High is bad. |
| `hygiene` | smallint NOT NULL DEFAULT 80 | 0–100. **0 = filthy, 100 = pristine.** Low is bad. |
| `happiness` | smallint NOT NULL DEFAULT 70 | 0–100. Higher is better. |
| `health` | smallint NOT NULL DEFAULT 75 | Derived stat, recalculated after every action. Never set directly. |
| `needs_meal` | boolean NOT NULL DEFAULT false | hunger > 70 |
| `needs_walk` | boolean NOT NULL DEFAULT false | happiness < 60 |
| `needs_bath` | boolean NOT NULL DEFAULT false | hygiene < 40 |
| `is_alive` | boolean NOT NULL DEFAULT true | Set to false when death conditions trigger. Dead pets cannot receive care. |
| `birth_date` | timestamp NOT NULL DEFAULT NOW() | When the pet was created |
| `last_interaction` | timestamp NOT NULL DEFAULT NOW() | Used by decay logic to calculate elapsed hours since last update |
| `created_at` / `updated_at` | timestamp | |

**Unique constraint:** `(user_id, name)` — same user cannot have two pets with the same name.

### Stat directions at a glance

```
hunger    → want LOW   (feed reduces it)
tiredness → want LOW   (sleep reduces it)
hygiene   → want HIGH  (bathe increases it)
happiness → want HIGH  (walk/play increase it)
health    → want HIGH  (derived — improves when others are in good range)
```

### How health is calculated

```
health = ((100 - hunger) + (100 - tiredness) + hygiene + happiness) / 4
```

All four inputs are normalized so that "good" always contributes positively.

### When a pet dies

Any of these conditions triggers `is_alive = false`:
- `hunger > 95` (starved)
- `hygiene < 10` (unsanitary)
- `happiness < 5` (despair)

Dead pets cannot be fed, walked, bathed, slept, or played with. They still appear in the list.

---

## inventories

One inventory per user, auto-created when the user registers. The inventory itself is just a container — actual items live in `inventory_slots`.

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigserial PK | |
| `user_id` | bigint FK → users UNIQUE | One-to-one |
| `created_at` / `updated_at` | timestamp | |

---

## inventory_slots

One row per (inventory, item) pair. The `qty` column tracks how many of that item the user holds.

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigserial PK | |
| `inventory_id` | bigint FK → inventories NOT NULL | |
| `item_id` | smallint NOT NULL | FK → items |
| `qty` | smallint NOT NULL DEFAULT 0 | Units held. Never goes negative. |

**Unique constraint:** `(inventory_id, item_id)` — one slot per item per inventory. Buying more increments `qty`; using an item decrements it.

---

## items

The item catalog. Seeded at app startup — not user data. These rows are fixed and never change at runtime.

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigserial PK | |
| `name` | varchar NOT NULL | Display name |
| `description` | text | Flavor text |
| `price_coins` | integer NOT NULL | Cost to buy from the shop |
| `hunger_delta` | smallint NOT NULL DEFAULT 0 | Applied to `pets.hunger` when item is used (negative = reduces hunger) |
| `hygiene_delta` | smallint NOT NULL DEFAULT 0 | |
| `happiness_delta` | smallint NOT NULL DEFAULT 0 | |
| `tiredness_delta` | smallint NOT NULL DEFAULT 0 | |

### Seeded items

| id | Name | hunger Δ | hygiene Δ | happiness Δ | tiredness Δ | Price |
|----|------|---------|---------|-----------|-----------|-------|
| 1 | Apple | -30 | 0 | +5 | 0 | 10 coins |
| 2 | Soap | 0 | +60 | 0 | 0 | 10 coins |
| 3 | Toy | 0 | 0 | +30 | +10 | 10 coins |
| 4 | Pillow | +5 | 0 | 0 | -60 | 10 coins |

Using an item applies the same stat-delta logic as a care action: `apply_time_decay` first, then apply deltas, then `refresh_needs_and_health`.

---

## claim_states

Tracks daily reward eligibility per (user, pet) pair. Prevents claiming more than once every 24 hours.

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigserial PK | |
| `user_id` | bigint FK → users NOT NULL | |
| `pet_id` | bigint FK → pets NOT NULL | |
| `last_claim_at` | timestamp | NULL if never claimed |
| `total_claims` | integer NOT NULL DEFAULT 0 | Lifetime claim count |

**Unique constraint:** `(user_id, pet_id)`.

### Reward amount

Base: 10 coins. Bonuses stack:
- +5 if `happiness ≥ 80`
- +5 if `health ≥ 80`
- +5 if `hunger ≤ 20 AND hygiene ≥ 80` (perfect care bonus)

Maximum per claim: **25 coins**.

---

## breed_records

Audit log of every breeding event. The offspring pet is a regular row in `pets` — this table just records the lineage.

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigserial PK | |
| `owner_id` | bigint FK → users NOT NULL | Must own both parents |
| `parent_a_id` | bigint FK → pets NOT NULL | |
| `parent_b_id` | bigint FK → pets NOT NULL | Must differ from parent_a |
| `offspring_id` | bigint FK → pets NOT NULL | The resulting new pet |
| `created_at` | timestamp | |

### Breeding rules

1. Both parents must be alive (`is_alive = true`).
2. Both parents must be owned by the same user.
3. `parent_a_id ≠ parent_b_id`.
4. Each stat of the offspring is randomly inherited from one parent (50/50 per stat, via `SecureRandom`).
5. Offspring species = first half of parent A's species + second half of parent B's species, truncated to 16 characters.

---

## Relationships at a glance

```
users
  ├── has_many :pets
  ├── has_one  :inventory
  │     └── has_many :inventory_slots
  │           └── belongs_to :item
  └── has_many :claim_states

pets
  └── has_many :claim_states

breed_records
  └── references users (owner), pets (parent_a, parent_b, offspring)
```

---

## Indexing notes

Add indexes on all FK columns. Worth adding:
- `pets(user_id)` — list all pets for a user
- `pets(is_alive)` — background job filters on this
- `inventory_slots(inventory_id, item_id)` — covered by unique constraint
- `claim_states(user_id, pet_id)` — covered by unique constraint
- `breed_records(owner_id)`, `breed_records(offspring_id)`
