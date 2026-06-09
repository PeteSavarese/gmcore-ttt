# GMCore

## Introduction and a Note
GMCore is the result of 10 years running and developing GMod servers, starting with my own server, TrueKnife TTT (2015), then After Hours Gaming (AHG, 2021), and now Giant's Lair (GL, 2025).

The repo includes a GitHub Actions workflow (currently commented out) that builds a Docker image and pushes it to GHCR. Pushes to main build the staging tag automatically. Production builds are a manual workflow run. The Pterodactyl eggs for staging and production each pull their matching tag, and Pterodactyl checks for a new image on every server start. To deploy an update, run the workflow and then restart the Pterodactyl server.

The main addon, `_gmcore`, integrates directly with the XenForo 2 addon `GMCore`. All punishments in-game (Bans, kicks, slays, etc.) are recorded directly in the database and read by the GMCore XenForo 2 addon. Players are not added to ranks in-game with ULX, but rather with their forum usergroup when they would sign up through Steam, with their SteamID being associated to their forum user. XenForo usergroup IDs are correlated to the proper ULX group.

A little note: I started learning to program at 12, tweaking existing GMod addons before building my own. At 14 I opened TrueKnife, which is where GMCore (originally `_tkttt_core`) took its roots. Every feature I wanted to add opened another door I didn't know existed. Joining AHG during its founding in 2021, the year I started college, I brought `_tkttt_core` with me and worked with someone I still consider my mentor. The biggest thing he taught me was to slow down and review my own work instead of racing to get a PR merged.

Giant's Lair is where the real work began. I managed a team of developers and ran a scrum board with 1-month sprints, pointing user stories, breaking them into tasks, and tracking them through development and testing on our staging server. Scheduled releases meant nobody was racing to push a bugfix/feature/change to production. If you finished in three days, great. You still had two weeks before it went live. It always ensure that we took our time testing our changes, rather than pushing them to production.

These days my focus is on what's next outside of GMod, but I'm proud of what this turned into and grateful for everyone I built it with. I'm releasing the repo as the finished form of that work, not as something I'll keep actively maintaining. Server owners, take it, fork/clone it, and make it your own. GMod is still alive and well, and the best form of creativity and uniquness per-server out there.

## Looking for the Main GMCore Code?
Jump to [main GMCore code](https://github.com/PeteSavarese/gmcore-ttt/tree/main/gmod-ttt/addons/_gmcore/lua) at `/addons/_gmcore/lua`.

## Local Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/PeteSavarese/gmcore-ttt.git
cd gmod-ttt
```

### 2. Configure Environment

Edit `gmod.env` to set local configuration:

```bash
DEPLOY_ENV=local              # Environment: local, staging, production
SERVER_NAME=GMCore      			# Server name
SERVER_PORT=27030             # Port for local testing
MAX_PLAYERS=32                # Maximum player count
MAP=ttt_minecraft_b5          # Starting map
...
```

### 3. Build and Run

Start server:
```bash
docker compose up -d
```

## Debugging

### Server Console Access

**Attach to SRCDS console:**
```bash
docker attach gmod-ttt-gmod-ttt-modded
```

Once attached to exit:
- Press `Ctrl+P` then `Ctrl+Q` to detach without stopping the server
- **Warning**: `Ctrl+C` will kill the server!

### Remote Debugging with RDB
GMRDB debugger with breakpoitns is only available in local development. To setup:

1. Install [GMRDB VScode extension](https://marketplace.visualstudio.com/items?itemName=metaman.gmrdb).
2. For clientside breakpoints, download [gmcl_rdb_{XXX}.dll](https://github.com/danielga/gm_rdb/releases)
  - Read the README.MD for this! If any server use this (which I suspect are rare), they can, in theory, breakpoint your client.
3. In server console: `rdb_activate`
4. Debug info appears in console

## Development Workflow

### Making Code Changes

1. **Addon Development**:
   - Normal GMod addon Lua work. Edit  `gmod-ttt/addons/`

2. **Server Configuration**:
   - Edit `gmod-ttt/cfg/server.cfg.template`
   - Rebuild container: `docker compose up --build`

### Linting Lua Code

The project uses LuaLS for linting and , type checking, and more.

1. Ensure [LuaLS VSCode extension](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) is installed
2. In VSCode, open the Command Palette with key combination Ctrl+Shift+P
3. Search for Addon, then select `Lua: Open Addon Manager ...`
4. Search for the **Garry's Mod** addon and enable it

## CI/CD Pipeline

### Workflows

1. **Build & Push** (`.github/workflows/build-push.yml`)
   - Builds Docker image
   - Pushes to GitHub Container Registry
   - Tags: `staging`, `latest`

### Image Structure

The Docker image:
1. Installs dependencies (32-bit libs for GMod)
2. Downloads GMod server files via SteamCMD (64-bit branch)
3. Bakes addons, cfg, data, lua, models into `/opt/gmod-server/`
4. On start, seeds or updates `/home/container/` from baked files

## Troubleshooting

### Can't Connect or Not in Local Network in Server Browser

1. Check firewall. For Linux users, make sure to open the port that this is set for (default: 27030) with, for example, UFW
2. Ensure `SERVER_PORT` matches port in `docker-compose.yaml`
