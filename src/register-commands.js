import { REST, Routes } from "discord.js";
import "dotenv/config";

const token = process.env.DISCORD_TOKEN || "";
const clientId = process.env.DISCORD_CLIENT_ID || "";

if (!token || !clientId) {
  console.error("Missing environment variables DISCORD_TOKEN or DISCORD_CLIENT_ID");
  process.exit(1);
}

const commands = [
  {
    name: "join",
    description: "Join your current voice channel or show the link to the web UI",
  },
  {
    name: "music",
    description: "Join your current voice channel or show the link to the web UI",
  },
  {
    name: "play",
    description: "Join your current voice channel or show the link to the web UI",
  },
  {
    name: "link",
    description: "Join your current voice channel or show the link to the web UI",
  }
];

const rest = new REST({ version: "10" }).setToken(token);

(async () => {
  try {
    console.log("Started refreshing application (/) commands.");

    console.log("Deleting old global commands...");
    await rest.put(
      Routes.applicationCommands(clientId),
      { body: [] }
    );
    console.log("Old global commands deleted.");

    console.log("Registering new global commands...");
    await rest.put(
      Routes.applicationCommands(clientId),
      { body: commands },
    );

    console.log("Successfully reloaded application (/) commands.");
  } catch (error) {
    console.error(error);
  }
})();
