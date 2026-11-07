#!/bin/bash
set -e

echo "=========================================="
echo "🚀 OnWay API AWS Deployment Script"
echo "=========================================="

echo "[1/4] Installing Node dependencies..."
npm install --legacy-peer-deps

echo "[2/4] Generating Prisma Client..."
npx prisma generate

echo "[3/4] Syncing Database Schema..."
npx prisma db push --accept-data-loss

echo "[4/4] Starting PM2 process manager..."
pm2 restart ecosystem.config.js || pm2 start ecosystem.config.js
pm2 save

echo "[+] Configuring systemd startup on reboot..."
bash ./scripts/setup-autostart.sh

echo "=========================================="
echo "✅ OnWay API Server Deployed Successfully!"
echo "=========================================="
