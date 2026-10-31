# Presence API

Member backend from `../PRD.md`. Node ≥ 23.6 runs the TypeScript directly; there is no build step.

```bash
npm install
cp .env.example .env              # set DATABASE_URL and SEED_PASSWORD (8+ chars)
npm run seed                      # runs migrations, resets the seed gym and member, prints a 24 h check-in code
npm start                         # API on $PORT (default 3000)
npm run code -- 60                # print a new check-in code valid for 60 seconds
npm run typecheck && npm test     # e2e tests wipe and reseed the seed gym in DATABASE_URL
```

Set `TRUST_PROXY=1` behind a load balancer so login rate limits see client IPs.
