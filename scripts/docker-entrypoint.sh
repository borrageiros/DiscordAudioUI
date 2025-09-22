#!/bin/bash
set -e

: "${DISCORD_TOKEN:?Error: DISCORD_TOKEN is not set.}"
: "${FRONTEND_URL:?Error: FRONTEND_URL is not set.}"
: "${VNC_PASSWORD:?Error: VNC_PASSWORD is not set.}"
: "${DISCORD_CLIENT_ID:?Error: DISCORD_CLIENT_ID is not set.}"

# Sync appuser password with ROOT_PASSWORD (fallback VNC_PASSWORD)
if id appuser >/dev/null 2>&1; then
  pw="${ROOT_PASSWORD:-${VNC_PASSWORD}}"
  if [ -n "$pw" ]; then
    echo "appuser:$pw" | chpasswd || true
  fi
fi

# Derive bot username for noVNC window title and icon for SO panel
NOVNC_TITLE="DiscordAudioUI"
if command -v curl >/dev/null 2>&1; then
  resp=$(curl -fsSL -H "Authorization: Bot ${DISCORD_TOKEN}" https://discord.com/api/v10/users/@me || true)
  if [ -n "$resp" ]; then
    name=$(printf '%s' "$resp" | sed -n 's/.*"global_name":"\([^"]*\)".*/\1/p')
    if [ -z "$name" ]; then
      name=$(printf '%s' "$resp" | sed -n 's/.*"username":"\([^"]*\)".*/\1/p')
    fi
    if [ -n "$name" ]; then
      NOVNC_TITLE="$name"
    fi

    uid=$(printf '%s' "$resp" | sed -n 's/.*"id":"\([0-9]*\)".*/\1/p')
    avh=$(printf '%s' "$resp" | sed -n 's/.*"avatar":"\([^"]*\)".*/\1/p')
    if [ -n "$uid" ] && [ -n "$avh" ]; then
      icon_url="https://cdn.discordapp.com/avatars/${uid}/${avh}.png?size=128"
      curl -fsSL "$icon_url" -o /usr/share/novnc/bot-icon.png || true
      install -D -m 644 /usr/share/novnc/bot-icon.png /usr/share/pixmaps/discord-bot.png || true
      gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
    fi
  fi
fi
export NOVNC_TITLE

# Patch noVNC HTML titles
for f in /usr/share/novnc/vnc.html /usr/share/novnc/vnc_lite.html; do
  if [ -f "$f" ]; then
    sed -i "s/<title>noVNC<\\/title>/<title>${NOVNC_TITLE//\//\/}<\\/title>/I" "$f" || true
    if [ -f /usr/share/novnc/bot-icon.png ]; then
      sed -i 's#<link rel="icon"[^>]*>##I' "$f" || true
      sed -i 's#</head>#<link rel="icon" href="bot-icon.png"></head>#I' "$f" || true
    fi
  fi
done

# Remove dynamic " - noVNC" suffix from title
if [ -f /usr/share/novnc/app/ui.js ]; then
  sed -i 's/ - noVNC//gI' /usr/share/novnc/app/ui.js || true
fi
cat >/usr/share/novnc/set-title.js <<EOF
document.addEventListener('DOMContentLoaded', function () {
  var t = ${NOVNC_TITLE@Q};
  document.title = t;
  var mo = new MutationObserver(function(){ if (document.title !== t) document.title = t; });
  mo.observe(document.querySelector('title')||document.head, {subtree:true,childList:true,characterData:true});
});
EOF
for f in /usr/share/novnc/vnc.html /usr/share/novnc/vnc_lite.html; do
  if [ -f "$f" ]; then
    grep -qi 'set-title.js' "$f" || sed -i 's#</head>#<script src="set-title.js"></script></head>#I' "$f" || true
  fi
done

# Execute the custom startup script
/app/scripts/custom-startup.sh

exec "$@"
