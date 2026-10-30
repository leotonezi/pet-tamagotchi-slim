# Tasks

GitHub issues are the source of truth. This file is a snapshot.
`gh` was not available when this was written, so open issues/PRs were not checked; every task below is marked "needs issue" until verified.

## Now

- Add Rack::Attack and limit care actions and reward claims to 10 req/min per user (IMPLEMENTATION.md Phase 9; CLAUDE.md security checklist; `rack-attack` not in `api/Gemfile`) — needs issue
- Fix README stat decay numbers: README says hunger/tiredness every 5 min and hygiene every 10 min, IMPLEMENTATION.md/CLAUDE.md say 1 per 4h/6h (README; commit adf43d2 "speed up stat decay rates"; which one is correct is inferred from the commit) — needs issue
- Add frontend tests and a working `npm run test`: README documents it, but `web/package.json` has no test script or vitest (README; CLAUDE.md Testing; package.json) — needs issue

## Next

- Add public read-only `GET /api/v1/widget/:pet_id` returning a pet snapshot, no auth (IMPLEMENTATION.md Phase 8; not in `api/config/routes.rb`) — needs issue
- Build `PetWidget.tsx` and wrap it as a web component with `@r2wc/react-to-web-component`; `web/src/widget/` is empty (IMPLEMENTATION.md Phase 8) — needs issue
- Add `/embed/:pet_id` iframe fallback page (IMPLEMENTATION.md Phase 8) — needs issue
- Add CI that runs rspec, tsc and lint; there is no `.github/` (inferred) — needs issue
- Deploy API to Railway and web to Vercel; only instructions exist, no deploy config in the repo (IMPLEMENTATION.md Phase 9; README Deployment; status is inferred) — needs issue

## Later

- Bring IMPLEMENTATION.md in line with what was built: all phase checkboxes are unticked though phases 1–7 are shipped, phase numbers differ from commit messages, and rewards are `/rewards` per user rather than `/rewards/:pet_id` (IMPLEMENTATION.md vs `routes.rb`, commits 3f64703, df702ea) — needs issue

## Ideas

- None found in the sources.
