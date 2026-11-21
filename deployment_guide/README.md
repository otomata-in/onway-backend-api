# Cloud Deployment & Maintenance Guide

This folder contains operational documentation for the backend services hosted within this repository:

1. **[Master Cloud Deployments Guide (OnWay + Teritory on Render)](RENDER_DEPLOYMENTS_MASTER.md)** ⭐
2. **[Teritory Travel & Expedition Platform Backend](teritory_backend_deployment.md)** (`teritory-api`, live on Render at `https://teritory-api.onrender.com` & Neon `teritory_db`).
3. **[OnWay Hyperlocal Marketplace Backend](backend_deployment.md)** (`onway-api`, live on Render at `https://onway-backend-api.onrender.com` & Neon `neondb`).

---

## 🛡️ Multi-Project Architecture & Separation

The repository houses two isolated projects. Actions taken on one project do not alter or disrupt the other:

| Component | Teritory Travel Platform | OnWay Marketplace |
| :--- | :--- | :--- |
| **API Path** | `./teritory-api` | `./src` (Root) |
| **Mobile App** | `./teritory` (Flutter) | OnWay Buyer & Vendor |
| **Cloud Database** | Neon Postgres (`teritory_db`) | Neon Postgres (`neondb`) |
| **Production Service** | `teritory-api` | `onway-backend-api` |
| **Default Port** | `4000` (Dev) / `10000` (Cloud) | `3001` (Dev) / `10000` (Cloud) |
| **Dedicated Guide** | [teritory_backend_deployment.md](teritory_backend_deployment.md) | [backend_deployment.md](backend_deployment.md) |

---

## 📁 Guide Table of Contents

1. **[Teritory API Deployment & Maintenance](teritory_backend_deployment.md)**
   * Deploying `teritory-api` on Render without affecting `onway-api`.
   * Standalone Docker and PM2 configurations.
   * Remote Neon database migrations & seeding rich Kazhakkoottam test data.
   * Testing authentication for user **Akhil V A** (`+91 8848793417`, OTP `12345`).
   * Configuring the Teritory Flutter application to connect to the live cloud URL.
2. **[OnWay Backend Deployment & Maintenance](backend_deployment.md)**
   * How automatic deployments work on git push for OnWay.
   * Render service configuration (`onway-backend-api`).
   * Environment variables and cache clearing.
3. **[OnWay Database Management & Migrations](database_management.md)**
   * Managing `neondb` on Lakebase serverless Postgres.
4. **[OnWay Flutter Integration & Testing](flutter_integration.md)**
   * Flutter Buyer & Vendor apps configuration.
