# Discord Audio UI Streamer 🎧

A powerful Dockerized solution to stream audio from a virtual desktop environment directly into a Discord voice channel. Manage a full Linux Desktop UI through your browser and share the audio output with your friends on Discord. Perfect for watch parties, music listening sessions, and more! 🥳

![Discord Audio UI Streamer](https://raw.githubusercontent.com/borrageiros/DiscordAudioUI/blob/main/readme/screenshot.png)

---

## ✨ Features

-   **🖥️ Full Linux Desktop**: Comes with an XFCE desktop environment accessible via any web browser (noVNC).
-   **🔊 High-Quality Audio Streaming**: Streams desktop audio directly to a Discord voice channel using FFmpeg.
-   **🤖 Simple Discord Commands**: Easy-to-use slash commands to control the bot (`/join`, `/music`, `/play`).
-   **🔗 Direct UI Access**: The bot provides a private link with a button to instantly access the VNC interface.
-   **🚶‍♂️ Auto-Disconnect**: The bot automatically leaves the voice channel when it's left alone.
-   **🔧 Highly Customizable**: Use environment variables to configure tokens, passwords, and even the bot's status!
-   **🚀 Extensible Startup**: Run your own custom installation scripts on container startup (e.g., install Spotify, VLC, etc.).
-   **🐳 Dockerized**: Easy to deploy and manage with Docker.

---

## 🚀 Getting Started

Follow these steps to get your Discord Audio UI Streamer up and running.

### Prerequisites

-   [Docker](https://www.docker.com/get-started) installed on your system.

### 1. Build the Docker Image

Clone this repository and build the Docker image with the following command:

```bash
docker build -t discord-audio-ui .
```

### 2. Docker Hub Images 📦

This project is automatically built and pushed to [Docker Hub](https://hub.docker.com/r/borrageiros/DiscordAudioUI) for two different CPU architectures. You can pull the images directly instead of building them locally.

-   **`borrageiros/DiscordAudioUI:latest`** (for `linux/amd64`)
    This is the standard image for most desktop PCs, servers, and cloud environments (Intel/AMD CPUs).

    ```bash
    docker pull borrageiros/DiscordAudioUI:latest
    ```

-   **`borrageiros/DiscordAudioUI:arm64`** (for `linux/arm64`)
    Use this image for ARM-based systems like Raspberry Pi, Apple Silicon (M1/M2/M3) Macs, or some cloud instances.

    ```bash
    docker pull borrageiros/DiscordAudioUI:arm64
    ```

> **Note**: When running a custom script (`custom.sh`), make sure any software you install is compatible with the architecture of the image you are using!

### 3. Register Commands

Before the first run, you need to register the slash commands with Discord's API. This requires your bot's token and client ID. Use the appropriate image tag for your system.

```bash
# For amd64 systems
docker run --rm \
  -e DISCORD_TOKEN="YOUR_DISCORD_TOKEN" \
  -e DISCORD_CLIENT_ID="YOUR_DISCORD_CLIENT_ID" \
  borrageiros/DiscordAudioUI:latest yarn register:commands

# For arm64 systems
docker run --rm \
  -e DISCORD_TOKEN="YOUR_DISCORD_TOKEN" \
  -e DISCORD_CLIENT_ID="YOUR_DISCORD_CLIENT_ID" \
  borrageiros/DiscordAudioUI:arm64 yarn register:commands
```

> **Note**: You only need to do this once, or whenever you change the command definitions.

### 4. Run the Container

Now you can run the main application. Here is an example `docker run` command. Make sure to replace the placeholder values with your own.

```bash
docker run -d \
  --name discord-audio-ui \
  --security-opt seccomp=unconfined \
  -p 6080:6080 \
  -v ./custom.sh:/app/custom.sh \
  -v ./mozilla_data:/home/appuser/.mozilla \
  \
  # --- Required Variables ---
  -e DISCORD_TOKEN="YOUR_DISCORD_TOKEN" \
  -e DISCORD_CLIENT_ID="YOUR_DISCORD_CLIENT_ID" \
  -e FRONTEND_URL="https://your-domain.com" \
  -e VNC_PASSWORD="A_STRONG_VNC_PASSWORD" \
  \
  # --- Optional Variables ---
  -e ACTIVITY_TYPE="Listening" \
  -e ACTIVITY="to your favorite tunes" \
  -e TZ="Europe/Madrid" \
  -e LANG="es_ES.UTF-8" \
  \
  discord-audio-ui
```

---

## ⚙️ Configuration

The container is configured using environment variables.

### Required Variables

| Variable            | Description                                                                                              |
| ------------------- | -------------------------------------------------------------------------------------------------------- |
| `DISCORD_TOKEN`     | Your Discord bot's token.                                                                                |
| `DISCORD_CLIENT_ID` | Your Discord application's client ID.                                                                    |
| `FRONTEND_URL`      | The public URL where the container is exposed (e.g., `http://your-ip:6080`). Used for the VNC link button. |
| `VNC_PASSWORD`      | The password to access the VNC web interface.                                                            |

### Optional Variables

| Variable        | Description                                                                                                           | Default                  |
| --------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `ACTIVITY_TYPE` | Sets the bot's activity type. Can be `Playing`, `Streaming`, `Listening`, `Watching`, `Competing`.                      | `Listening`              |
| `ACTIVITY`      | Sets the text for the bot's activity (e.g., "Listening to **music**").                                                  | `music`                  |
| `PULSE_SOURCE`  | The PulseAudio source to capture audio from.                                                                          | `Virtual_Sink.monitor`   |
| `TZ`            | Sets the timezone for the container, e.g., `America/New_York`.                                                        | `Etc/UTC`                |
| `LANG`          | Sets the locale for the container, e.g., `en_US.UTF-8`.                                                               | `C.UTF-8`                |

### Volumes

| Local Path              | Container Path                | Description                                                                                                   |
| ----------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `./custom.sh`           | `/app/custom.sh`              | **(Optional)** A shell script that runs on startup to perform custom installations or configurations.         |
| `./mozilla_data`        | `/home/appuser/.mozilla`      | **(Optional)** Persists Firefox data (cookies, history, etc.) across container restarts.                      |

---

## 🤖 Usage

1.  **Invite the bot** to your Discord server.
2.  Join a voice channel.
3.  Type `/join` (or `/music`, `/play`, `/link`).
4.  The bot will join your channel and send you a **private message** with a button.
5.  Click the **"Open Web UI"** button to access the virtual desktop.
6.  Open any application (like Firefox or a custom-installed app like Spotify) and play audio. The audio will be streamed to the voice channel!
7.  When everyone leaves the channel, the bot will automatically disconnect.
