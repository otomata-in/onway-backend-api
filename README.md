# OnWay — Backend API

Lightweight, real-time hyperlocal marketplace backend for connecting buyers with moving vendors (seller and buyer mobile apps).

## Key points
- API + Socket real-time features (vendor location, order tokens, proximity alerts)
- Built with Node.js, Express, Sequelize (MySQL), Redis, and Socket.IO
- Detailed API and architecture docs: `docs/`

## Features
- OTP-based authentication (mobile number)
- Token-based order intents (non-guaranteed orders)
- Seller route system and live location tracking (Redis-backed)
- Inventory, orders, vendor discovery, FCM notifications
- Rate limiting, input validation, graceful shutdown

## Tech stack
- Node.js + Express
- MySQL (Sequelize)
- Redis (ioredis)
- Socket.IO (realtime)
- Firebase Cloud Messaging (FCM) for push notifications

## Repo structure (important folders)

- `src/` — application source
	- `config/` — config loaders (env)
	- `models/`, `migrations/` — Sequelize models and migrations
	- `modules/` — feature modules (auth, user, seller, vendor, inventory, order)
	- `middleware/` — auth, validation, error handling, rate limiting
	- `utils/` — helpers (ApiResponse, ApiError, otp, sms)
	- `app.js` — Express app (routes, middleware)
	- `server.js` — server bootstrap (DB + Redis connection + graceful shutdown)

## Docs
See the full design and API specification in the `docs/` folder:

- `docs/on_way_market_api_detailed_specification.md` — API endpoints and request/response details
- `docs/on_way_market_backend_design.md` — backend design and architecture
- `docs/on_way_market_frontend_product_specification.md` — frontend product spec and flows

## Quick start (development)

Prerequisites:
- Node.js (v18+ recommended)
- MySQL
- Redis

1. Install dependencies

```bash
npm install
```

2. Create a `.env` in the project root with these example values:

```
PORT=3000
NODE_ENV=development

DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=yourpassword
DB_NAME=onway

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

AUTH_TOKEN_SECRET=replace-with-secure-secret
OTP_EXPIRY_SECONDS=300
```

3. Run database migrations

```bash
npm run migrate
```

4. Start the server (development)

```bash
npm run dev
```

Or run production mode:

```bash
npm start
```

## Available npm scripts

- `start` — run `node src/server.js`
- `dev` — run `nodemon src/server.js`
- `migrate` — run Sequelize migrations (`npx sequelize-cli db:migrate`)
- `migrate:undo` — undo last migration
- `migrate:undo:all` — undo all migrations
- `seed` — run DB seeds (`npx sequelize-cli db:seed:all`)

## Environment variables (summary)

- `PORT` — HTTP port (default: 3000)
- `NODE_ENV` — environment
- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` — MySQL settings
- `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` — Redis settings
- `AUTH_TOKEN_SECRET` — JWT / token secret
- `OTP_EXPIRY_SECONDS` — OTP TTL in seconds

## API & Endpoints
See `docs/on_way_market_api_detailed_specification.md` for a complete list of endpoints, request/response formats, and behavior (OTP flow, vendor routes, order tokens, realtime events).

## Contributing
- Follow existing code patterns in `src/modules/*` and middleware.
- Run migrations when altering models.

## Next steps you might want
- Add an `.env.example` file with recommended values
- Add a Postman/Insomnia collection or OpenAPI spec
- CI to run lint/tests and (optional) automated deploys

----
Updated README to include project overview, setup, and docs links.
