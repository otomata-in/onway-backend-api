# OnWay API — Cloud Deployment & Maintenance Guide

This folder contains the complete operational documentation for the deployed **OnWay Hyperlocal Marketplace Backend** and **Lakebase PostgreSQL Database**.

---

## 🌐 Quick Links & Service Information

| Resource | Value / Link | Notes |
| :--- | :--- | :--- |
| **Live API Base URL** | `https://onway-backend-api.onrender.com` | Root endpoint returns service health status |
| **API Version 1 Prefix** | `https://onway-backend-api.onrender.com/api/v1` | Used by Flutter Buyer and Vendor apps |
| **API Documentation (Swagger UI)** | `https://onway-backend-api.onrender.com/api-docs/` | Interactive OpenAPI documentation |
| **Render Dashboard** | [dashboard.render.com](https://dashboard.render.com/web/srv-dbnm5rrl550s73fjluq0) | Manage web service, logs, environment variables |
| **Neon Database Console** | [console.neon.tech](https://console.neon.tech/) | Project: `cool-pond-82585350`, Branch: `production` |
| **GitHub Repository** | [github.com/otomata-in/onway-backend-api](https://github.com/otomata-in/onway-backend-api) | Primary production codebase repository |

---

## 🏛 Architecture Overview

```
                      ┌────────────────────────────────┐
                      │   Flutter Apps (Vendor/Buyer)  │
                      └──────────────┬─────────────────┘
                                     │ HTTPS / WSS
                                     ▼
                      ┌────────────────────────────────┐
                      │    Render Web Service          │
                      │  (Node.js 22 + Express 5)      │
                      │  Port: 10000 (bind 0.0.0.0)    │
                      └──────┬──────────────────┬──────┘
                             │                  │
           Prisma Runtime    │                  │  ioredis (Optional)
       Pooled Query (5432)   │                  │  Graceful Fallback
                             ▼                  ▼
              ┌────────────────────────┐  ┌───────────┐
              │    Neon PostgreSQL     │  │  Upstash  │
              │  (Lakebase Serverless) │  │   Redis   │
              │  Project: cool-pond... │  └───────────┘
              └────────────────────────┘
```

---

## 📁 Guide Table of Contents

1. **[Backend Deployment & Maintenance](backend_deployment.md)**
   * How automatic deployments work on git push.
   * How to manually trigger deploys or rebuild with clear cache.
   * Managing environment variables on Render.
   * Viewing logs and diagnosing container issues.
2. **[Database Management & Migrations](database_management.md)**
   * How Prisma connects to Neon (Pooled vs. Direct connection strings).
   * Modifying Prisma schema and deploying changes to the live database (`prisma db push`).
   * Neon branching workflows for safe testing without risking production data.
   * Using the Neon CLI and MCP tools.
3. **[Flutter Integration & Testing](flutter_integration.md)**
   * Configuration of `baseUrl` in Flutter Vendor and Buyer applications.
   * Testing endpoints from physical devices anywhere in the world.
   * Handling authentication tokens and Socket.IO connections.
