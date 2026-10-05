# Burnout Paradise (PC) — private server revival

A community preservation project: a private online server and client setup for **Burnout Paradise: The Ultimate Box**
(PC / Steam, build 1.0.0.1). EA shut down the game's online services years ago. This project lets you run your own
server so owners of the game can sign in, host Freeburn sessions and drive together again.

> **You need your own legitimate copy of the game.** This repository contains no game files, no game executable and no
> patched executables. See [docs/LEGAL.md](docs/LEGAL.md).

## Status

| Feature | State |
| --- | --- |
| Server: login, account creation, Freeburn hosting/joining | Working. Two PCs on one LAN drove, raced and crashed together (October 2026). |
| Server on Linux | Builds for linux-x64; **not yet tested on a real Linux host** |
| More than 2 simultaneous players | Configurable (`MAX_USERS`), **untested** |
| Road-rule record uploads | Stored on the server (`road-rules.json`) |
| In-game leaderboards / ranks | **Not working yet** (see [docs/PROTOCOL-NOTES.md](docs/PROTOCOL-NOTES.md)) |
| Career profile sync | No. Profiles are saved locally on each PC. |
| Internet play | Untested. Designed and tested for a LAN. See security notes. |

## How it works (short)

1. The game looks up `pcburnout08.ea.com`. A one-line **hosts file entry** points it at your server.
2. The server speaks the game's legacy SSL 3 + "Aries/Dirtysock" protocol (a patched build of the open-source
   [PSHome MultiServer](https://github.com/GitHubProUser67/PSHome-MultiServer) `MultiSocks` service).
3. The game only trusts EA's original certificate authority, so each player runs a small **hash-verified patch script**
   that makes a *separate copy* of their own `BurnoutParadise.exe` which trusts this project's test certificate authority.
   Your original executable is never modified.
4. After login the players' PCs exchange game traffic directly (UDP) like the original game did.

## Quick start

Full instructions: **[docs/SETUP.md](docs/SETUP.md)**.

```powershell
# 1. Build the server (needs the .NET 6 SDK) -> .\dist\win-x64 and .\dist\linux-x64
powershell -ExecutionPolicy Bypass -File .\scripts\Build-Server.ps1

# 2. Run the server (Windows)
.\dist\win-x64\Start-Server.ps1 -ServerAddress 192.168.1.50
#    ...or Linux:  SERVER_IP=192.168.1.50 bash dist/linux-x64/run-server.sh

# 3. On each player PC (elevated PowerShell, Steam installed with the game)
powershell -ExecutionPolicy Bypass -File .\client\Install-Client.ps1 -GameDirectory "<game folder>" -ServerAddress 192.168.1.50
```

## Repository layout

| Path | Contents |
| --- | --- |
| `server/` | Source for the patched MultiSocks server and the projects it needs (GPL-3.0) |
| `scripts/` | `Build-Server.ps1`, server launchers, systemd unit, test certificates |
| `client/` | Per-PC setup: client patch script, hosts redirect, firewall rule |
| `docs/` | Setup guide, how it works, protocol notes, known issues, legal |

## Security notes

* The server speaks **SSL 3 with RC4** because the 2008 game requires it. Run it only on a trusted LAN or behind a
  firewall that allows just your players.
* Accounts are created on first login and **passwords are stored in clear text** in `static/local-accounts.json`
  (an upstream design). Use throwaway passwords; never reuse a real one.
* The client patch swaps in a publicly known *test* key. Anyone can impersonate this server's certificate authority,
  so do not treat this as secure transport.

## Credits and licences

GPL-3.0. Built on [PSHome MultiServer](https://github.com/GitHubProUser67/PSHome-MultiServer) (MultiSocks, GPL-3.0) and
the protocol research and test certificates from [eaEmu](https://github.com/teknogods/eaEmu) (GPL-3.0).
Burnout and Burnout Paradise are trademarks of Electronic Arts Inc.; this project is unaffiliated.
