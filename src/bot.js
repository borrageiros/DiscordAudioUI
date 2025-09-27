import { Client, GatewayIntentBits, ActionRowBuilder, ButtonBuilder, ButtonStyle, ActivityType } from "discord.js";
import { joinVoiceChannel, createAudioPlayer, createAudioResource, StreamType, AudioPlayerStatus, NoSubscriberBehavior, VoiceConnectionStatus, entersState } from "@discordjs/voice";
import { spawn } from "child_process";
import prism from "prism-media";

const token = process.env.DISCORD_TOKEN || "";
const pulseSource = process.env.PULSE_SOURCE || "Virtual_Sink.monitor";
const frontendUrl = process.env.FRONTEND_URL || "";
const vncPassword = process.env.VNC_PASSWORD || "";
const activityType = process.env.ACTIVITY_TYPE || "Listening";
const activityName = process.env.ACTIVITY || "music";

if (!token || !frontendUrl || !vncPassword) {
  console.error("Missing environment variables DISCORD_TOKEN, FRONTEND_URL or VNC_PASSWORD");
  process.exit(1);
}

const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildVoiceStates] });

let player = createAudioPlayer({ behaviors: { noSubscriber: NoSubscriberBehavior.Play, maxMissedFrames: 20 } });
let currentConnection = null;
let restarting = false;
let restartTimer = null;

function spawnFfmpeg() {
  const args = [
    "-thread_queue_size",
    "2048",
    "-f",
    "pulse",
    "-use_wallclock_as_timestamps",
    "1",
    "-i",
    pulseSource,
    "-flags",
    "+low_delay",
    "-max_interleave_delta",
    "0",
    "-fflags",
    "+nobuffer+genpts",
    "-avoid_negative_ts",
    "make_zero",
    "-flush_packets",
    "1",
    "-vn",
    "-map_metadata",
    "-1",
    "-ac",
    "2",
    "-ar",
    "48000",
    "-f",
    "s16le",
    "pipe:1"
  ];
  const proc = spawn("ffmpeg", args, {
    stdio: ["ignore", "pipe", "inherit"],
    env: { ...process.env, PULSE_LATENCY_MSEC: process.env.PULSE_LATENCY_MSEC || "120" }
  });
  return proc;
}

function scheduleRestart(delayMs = 1000) {
  if (restarting) return;
  restarting = true;
  if (restartTimer) clearTimeout(restartTimer);
  restartTimer = setTimeout(() => {
    restarting = false;
    startStreamingLoop();
  }, delayMs);
}

function startStreamingLoop() {
  const ff = spawnFfmpeg();
  let resource;
  try {
    const encoder = new prism.opus.Encoder({ rate: 48000, channels: 2, frameSize: 960 });
    encoder.on("error", () => scheduleRestart());
    ff.on("close", () => scheduleRestart());
    const opusStream = ff.stdout.pipe(encoder);
    resource = createAudioResource(opusStream, { inputType: StreamType.Opus });
  } catch (e) {
    const alt = spawn("ffmpeg", [
      "-thread_queue_size", "4096",
      "-f", "pulse",
      "-use_wallclock_as_timestamps", "1",
      "-i", pulseSource,
      "-flags", "+low_delay",
      "-max_interleave_delta", "0",
      "-fflags", "+nobuffer+genpts",
      "-avoid_negative_ts", "make_zero",
      "-vn",
      "-map_metadata", "-1",
      "-ac", "2",
      "-ar", "48000",
      "-c:a", "libopus",
      "-b:a", "128k",
      "-f", "ogg",
      "pipe:1"
    ], { stdio: ["ignore", "pipe", "inherit"], env: process.env });
    alt.on("close", () => scheduleRestart());
    resource = createAudioResource(alt.stdout, { inputType: StreamType.OggOpus });
  }
  if (resource && resource.playStream && resource.playStream.on) {
    resource.playStream.on("error", () => scheduleRestart());
  }
  player.play(resource);
}

async function closeAllApps() {
  try {
    const cmd = "ids=$(wmctrl -lx | awk '!/xfce4-panel\.Xfce4-panel|xfdesktop\.Xfdesktop|xfce4-session-logout/ {print $1}'); for w in $ids; do wmctrl -ic $w || true; done; pkill -f xfce4-session-logout || true; sleep 0.5; rem=$(xprop -root _NET_CLIENT_LIST 2>/dev/null | tr -d ',' | awk '{for(i=5;i<=NF;i++) print $i}'); for w in $rem; do xwininfo -id $w 2>/dev/null | grep -qi 'xfce4-session-logout' && continue; xkill -id $w || true; done";
    spawn("bash", ["-lc", cmd], { stdio: ["ignore", "ignore", "inherit"] });
  } catch { }
}

async function joinAndStream(targetGuildId, targetChannelId) {
  const guild = await client.guilds.fetch(targetGuildId);
  const channel = await guild.channels.fetch(targetChannelId);
  if (!channel || channel.type !== 2) {
    throw new Error("Voice channel not found or not a voice channel");
  }

  if (currentConnection) {
    try { currentConnection.destroy(); } catch { }
    currentConnection = null;
  }

  const connection = joinVoiceChannel({
    channelId: targetChannelId,
    guildId: targetGuildId,
    adapterCreator: guild.voiceAdapterCreator
  });
  currentConnection = connection;
  connection.subscribe(player);
  connection.on("stateChange", (oldState, newState) => {
    console.log("VoiceConnection state:", oldState.status, "->", newState.status);
  });
  try {
    await entersState(connection, VoiceConnectionStatus.Ready, 20_000);
  } catch (e) {
    console.error("Voice connection failed:", e);
    try { connection.destroy(); } catch { }
    throw e;
  }
  startStreamingLoop();
}

client.once("ready", async () => {
  console.log("Bot is ready as", client.user?.tag);

  let discordActivityType;
  switch (activityType.toLowerCase()) {
    case 'playing':
      discordActivityType = ActivityType.Playing;
      break;
    case 'streaming':
      discordActivityType = ActivityType.Streaming;
      break;
    case 'watching':
      discordActivityType = ActivityType.Watching;
      break;
    case 'competing':
      discordActivityType = ActivityType.Competing;
      break;
    case 'listening':
    default:
      discordActivityType = ActivityType.Listening;
      break;
  }

  client.user.setPresence({
    activities: [{ name: activityName, type: discordActivityType }],
    status: 'online',
  });
});
player.on("error", (err) => {
  console.error("AudioPlayer error:", err?.message || String(err));
  scheduleRestart();
});
player.on("stateChange", (oldState, newState) => {
  console.log("AudioPlayer state:", oldState.status, "->", newState.status);
  if (newState.status === AudioPlayerStatus.Idle) {
    scheduleRestart();
  }
});

client.on("voiceStateUpdate", (oldState, newState) => {
  if (oldState.channelId === newState.channelId) return;
  if (!currentConnection || oldState.channelId !== currentConnection.joinConfig.channelId) return;

  const channel = oldState.channel;
  if (channel && channel.members.size === 1 && channel.members.has(client.user.id)) {
    console.log("Bot is alone in the channel, disconnecting.");
    closeAllApps();
    currentConnection.destroy();
    currentConnection = null;
  }
});


client.on("interactionCreate", async (interaction) => {
  if (!interaction.isChatInputCommand()) return;

  const { commandName } = interaction;

  if (commandName === "join" || commandName === "music" || commandName === "play" || commandName === "link") {
    const member = interaction.member;
    const voiceChannel = member.voice.channel;

    if (!voiceChannel) {
      await interaction.reply({ content: "You must be in a voice channel to use this command.", ephemeral: true });
      return;
    }

    if (voiceChannel.type !== 2) {
      await interaction.reply({ content: "You must be in a valid voice channel.", ephemeral: true });
      return;
    }

    await interaction.deferReply({ ephemeral: true });
    try {
      await joinAndStream(interaction.guildId, voiceChannel.id);

      const url = `${frontendUrl}/vnc.html?autoconnect=true&resize=scale&password=${vncPassword}&quality=6&compression=2&cursor=local&enableWebP=true&reconnect=true&reconnect_delay=2000`;

      const linkButton = new ButtonBuilder()
        .setLabel("Open Web UI")
        .setURL(url)
        .setStyle(ButtonStyle.Link);

      const row = new ActionRowBuilder().addComponents(linkButton);

      await interaction.editReply({
        content: ``,
        components: [row]
      });
    } catch (e) {
      console.error(e);
      await interaction.editReply("Failed to join channel. Please check my permissions.");
    }
  }
});

client.login(token).catch((e) => {
  console.error("Login failed:", e);
  process.exit(1);
});


