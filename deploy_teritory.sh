#!/bin/bash
set -e

echo "=========================================="
echo "🚀 Teritory Standalone API Deployment Script"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERITORY_DIR="$SCRIPT_DIR/teritory-api"

cd "$TERITORY_DIR"

echo "[1/4] Installing Teritory dependencies..."
npm install

echo "[2/4] Generating Prisma client for Teritory schema..."
npx prisma generate

echo "[3/4] Syncing Teritory Database Schema (teritory_db)..."
npx prisma db push --accept-data-loss

if [ "$1" == "--seed" ]; then
  echo "[+] Seeding database with Kazhakkoottam & Kerala test dataset..."
  node prisma/seed.js
fi

echo "[4/4] Starting/Restarting Teritory API in PM2 (Port 4000)..."
cd "$SCRIPT_DIR"
pm2 restart ecosystem.config.js --only teritory-api 2>/dev/null || pm2 start ecosystem.config.js --only teritory-api 2>/dev/null || {
  echo "[i] PM2 not running globally; starting standalone process with node..."
  (cd "$TERITORY_DIR" && PORT=4000 node src/server.js &)
}

echo "=========================================="
echo "✅ Teritory API Deployed Successfully!"
echo "   Endpoint: http://localhost:4000/v1"
echo "   Health:   http://localhost:4000/health"
echo "=========================================="
