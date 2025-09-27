FROM ubuntu:22.04

ARG LANG_ARG=C.UTF-8
ARG TZ_ARG=Etc/UTC

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=${LANG_ARG} \
    LANGUAGE=${LANG_ARG} \
    LC_ALL=${LANG_ARG} \
    TZ=${TZ_ARG}

RUN apt-get update && apt-get install -y \
    locales \
    ca-certificates curl git supervisor \
    pulseaudio-utils pulseaudio alsa-utils pavucontrol pasystray \
    tigervnc-standalone-server tigervnc-common xfce4 xfce4-goodies xfce4-terminal wmctrl x11-utils \
    novnc websockify xfonts-base xauth \
    dbus-x11 x11-xserver-utils build-essential python3 make g++ pkg-config libopus-dev \
    libgl1-mesa-glx \
    ffmpeg \
    vlc \
    software-properties-common \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN echo "${LANG_ARG} UTF-8" > /etc/locale.gen && \
    locale-gen

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    corepack enable && corepack prepare yarn@4.3.1 --activate && \
    rm -rf /var/lib/apt/lists/*

RUN add-apt-repository -y ppa:mozillateam/ppa && \
    printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' > /etc/apt/preferences.d/mozillateamppa && \
    apt-get update && apt-get install -y --allow-downgrades firefox && \
    update-alternatives --set x-www-browser /usr/bin/firefox && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash appuser
RUN usermod -aG sudo appuser

WORKDIR /app

COPY package.json .yarnrc.yml ./
ENV npm_config_build_from_source=true
RUN yarn install --mode=skip-build || yarn install

COPY config/xfce4 /home/appuser/.config/xfce4
RUN rm -f /etc/xdg/autostart/xfce4-power-manager.desktop
RUN rm -f /etc/xdg/autostart/xfce4-screensaver.desktop || true
RUN apt-get purge -y xfce4-screensaver light-locker xscreensaver || true && \
    apt-get autoremove -y && apt-get clean

# Create Desktop directory and Firefox, VLC shortcuts
RUN mkdir -p /home/appuser/Desktop && \
    cp /usr/share/applications/firefox.desktop /home/appuser/Desktop/ && \
    cp /usr/share/applications/vlc.desktop /home/appuser/Desktop/ && \
    chmod +x /home/appuser/Desktop/*.desktop

# Patch @discordjs/voice to accept *_rtpsize modes by mapping them to supported xsalsa20 modes
RUN true

COPY . .
RUN sed -i 's/\r$//' /app/scripts/*.sh /app/scripts/xstartup

RUN chmod +x /app/scripts/*.sh && mkdir -p /home/appuser/.vnc && chown -R appuser:appuser /home/appuser /app
RUN chmod +x /app/scripts/custom-startup.sh

ENV DISPLAY=:1 \
    PULSE_SERVER=unix:/tmp/runtime-appuser/pulse/native \
    HOME=/home/appuser

ENV DISCORD_TOKEN="" \
    FRONTEND_URL="" \
    VNC_PASSWORD="" \
    DISCORD_CLIENT_ID=""

# Normalize line endings if the context comes with CRLF
RUN sed -i 's/\r$//' /app/scripts/*.sh /app/scripts/xstartup || true

EXPOSE 6080

ENTRYPOINT ["/app/scripts/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/app/supervisord.conf"]
