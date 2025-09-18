#!/bin/bash
set -e

: "${DISCORD_TOKEN:?Error: DISCORD_TOKEN is not set.}"
: "${FRONTEND_URL:?Error: FRONTEND_URL is not set.}"
: "${VNC_PASSWORD:?Error: VNC_PASSWORD is not set.}"
: "${DISCORD_CLIENT_ID:?Error: DISCORD_CLIENT_ID is not set.}"

# Execute the custom startup script
/app/scripts/custom-startup.sh

exec "$@"
