# Database Management & Migrations Guide (Neon PostgreSQL)

This document details how the database is structured on Neon Lakebase PostgreSQL, how Prisma connects to it, and how to safely apply schema updates.

---

## 1. Neon Project Information

* **Project Name**: `cool-pond-82585350`
* **Organization ID**: `org-old-frog-16433060`
* **Default Branch**: `production` (`br-sparkling-star-bervpk88`)
* **Region**: AWS `us-east-2` (Ohio)
* **Storage Engine**: Lakebase Serverless Postgres (0.5 GB Free Tier, does not expire after 30 days)

---

## 2. Connection Strategy (Pooled vs. Direct)

In accordance with Neon and Prisma best practices, your [prisma/schema.prisma](file:///home/akhilva/onway-api/prisma/schema.prisma) is configured with two connection endpoints:

```prisma
datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DATABASE_URL_UNPOOLED")
}
```

### Why two URLs?
1. **`DATABASE_URL` (Pooled Endpoint)**:
   * Contains `-pooler` in the hostname (e.g. `ep-noisy-bar-be1d5ayd-pooler...`).
   * Connects via Neon's built-in PgBouncer connection pooler.
   * Handles thousands of simultaneous concurrent connections from the Express API with low memory overhead.
2. **`DATABASE_URL_UNPOOLED` (Direct Endpoint)**:
   * Connects directly to the Postgres instance without PgBouncer.
   * Used for running migrations, `prisma db push`, and schema alterations that require transactional session commands.

---

## 3. How to Update Database Schema

Whenever you modify models or add fields in [prisma/schema.prisma](file:///home/akhilva/onway-api/prisma/schema.prisma):

### Step 1: Edit the Schema
Open `prisma/schema.prisma` and make your changes (e.g. adding a new column to a table).

### Step 2: Push Changes to Neon Cloud Database
Run the following command from the project root:
```bash
npx prisma db push
```
This directly connects to the Neon direct endpoint (`DATABASE_URL_UNPOOLED`), alters the tables in the cloud without dropping unrelated data, and regenerates your local `@prisma/client`.

### Step 3: Test and Commit
```bash
# Verify build passes
npm run build

# Commit schema changes
git add prisma/schema.prisma
git commit -m "feat(db): add new columns to vendor model"
git push origin main
```
*Once pushed, Render will automatically pull the updated code and run `npm run build` to update the Prisma client on the live server.*

---

## 4. Neon Branching Workflow (Safe Testing)

Neon provides copy-on-write instant branching. You can create a full clone of your production database for testing experimental features or running disruptive schema migrations:

### Create a Development Branch
```bash
# Create and switch to a branch named 'staging' or 'dev'
neon checkout dev --create
```
This creates an isolated sandbox with a copy of all current tables and rows. You get a separate `DATABASE_URL` for this branch without affecting production users.

### Return to Production Branch
```bash
neon checkout production
```

### Sync Local Environment Variables
If Neon credentials change or you need to re-pull the branch's connection strings:
```bash
neon env pull
```
*(Pulls fresh variables into `.env.local` / `.env`).*

---

## 5. Direct Database Access (Neon CLI & psql)

You can query the database directly using the Neon CLI:
```bash
# Open interactive SQL prompt on production
neon sql

# Example query:
SELECT count(*) FROM users;
```
Or view the database visual explorer in the [Neon Console](https://console.neon.tech/).

