#!/usr/bin/env bash
set -euo pipefail
export USER=appuser
export HOME=/home/appuser
mkdir -p "$HOME/.vnc"
password=${VNC_PASSWORD:-vncpassword}
echo "$password" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"
install -m 755 /app/scripts/xstartup "$HOME/.vnc/xstartup"
sed -i 's/\r$//' "$HOME/.vnc/xstartup"
vncserver -kill :1 >/dev/null 2>&1 || true
geometry=${VNC_GEOMETRY:-1600x780}
# Clean orphan locks
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 || true
vncserver :1 -geometry "$geometry" -depth 16 -localhost yes -name "${NOVNC_TITLE:-Discord Audio UI}"
export DISPLAY=:1
sleep 1
# Force disable screensaver/lock via xfconf
if command -v xfconf-query >/dev/null 2>&1; then
  xfconf-query -c xfce4-screensaver -p /saver/enabled -n -t bool -s false || true
  xfconf-query -c xfce4-screensaver -p /saver/lock-enabled -n -t bool -s false || true
  xfconf-query -c xfce4-screensaver -p /saver/idle-activation-enabled -n -t bool -s false || true
fi
# Kill any running lockers just in case
pkill -f xfce4-screensaver || true
pkill -f light-locker || true
logfile=$(ls -1t $HOME/.vnc/*.log | head -n1 || true)
if [ -n "$logfile" ]; then
  tail -F "$logfile" || true
else
  while true; do sleep 3600; done
fi

