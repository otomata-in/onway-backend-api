#!/bin/bash
set -e

echo "=========================================="
echo "⚙️  Configuring OnWay API Auto-Start on System Boot"
echo "=========================================="

CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~$CURRENT_USER)

# 1. Enable Nginx on boot
if command -v nginx &> /dev/null; then
    echo "Enabling Nginx service on boot..."
    sudo systemctl enable nginx
    sudo systemctl restart nginx
fi

# 2. Enable Docker on boot (for Postgres/Redis if containerized)
if command -v docker &> /dev/null; then
    echo "Enabling Docker service on boot..."
    sudo systemctl enable docker
fi

# 3. Configure PM2 systemd startup hook
if command -v pm2 &> /dev/null; then
    echo "Configuring PM2 startup hook for user: $CURRENT_USER..."
    STARTUP_CMD=$(pm2 startup systemd -u "$CURRENT_USER" --hp "$USER_HOME" | grep "sudo env" | head -n 1)
    if [ -n "$STARTUP_CMD" ]; then
        echo "Executing systemd hook: $STARTUP_CMD"
        eval "$STARTUP_CMD"
    fi

    # Ensure ecosystem is started and save current process list
    APP_DIR="$USER_HOME/onway-api"
    if [ ! -d "$APP_DIR" ]; then
        APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
    fi

    cd "$APP_DIR"
    pm2 restart ecosystem.config.js || pm2 start ecosystem.config.js
    pm2 save
    echo "✅ PM2 process list successfully saved to ~/.pm2/dump.pm2"
fi

echo "=========================================="
echo "✅ Auto-start configured! OnWay API will restart on any server boot."
echo "=========================================="
