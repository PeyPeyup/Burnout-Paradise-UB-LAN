# Setup guide

## What you need

* **Server machine** (Windows, or x86-64 Linux) reachable by every player. Its IPv4 address (called `SERVER_IP`
  below) is the address the game clients will use.
* **Each player PC** (Windows) with **Burnout Paradise: The Ultimate Box** installed from Steam, build **1.0.0.1**
  (`BurnoutParadise.exe` SHA-256 `FA55FF4D5B0F0F1E7A3DD861EC765D1D81C51554B588AE9872A3F923686F41BE`). The patch script
  refuses to run on any other build.
* To build the server: the [.NET 6 SDK](https://dotnet.microsoft.com/download/dotnet/6.0) (end-of-life, but it is what
  the project targets and is tested with).

## 1. Build the server

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Build-Server.ps1
```

Output: `dist/win-x64` and `dist/linux-x64`, each self-contained (no .NET install needed to run) with the launcher
script and the test certificates. Pass `-Dotnet <path>` if `dotnet` is not on your PATH.

## 2. Run the server

Open these ports to your players: **TCP 21841 and 21842**.

Windows:
```powershell
.\dist\win-x64\Start-Server.ps1 -ServerAddress <SERVER_IP> [-MaxUsers 2]
```

Linux:
```bash
SERVER_IP=<SERVER_IP> MAX_USERS=2 bash dist/linux-x64/run-server.sh
```
A systemd unit (`burnout-private.service`) is included for running it as a service. The first Linux run is
untested by the authors; please report what happens.

You should see `Started Aries Redirector on port 21841` and `Started Aries Matchmaker on port 21842`.
Account data is kept in `static/local-accounts.json` next to the server; back it up and keep it private.

## 3. Set up each player PC

Run in an **elevated** PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\client\Install-Client.ps1 `
    -GameDirectory "C:\Program Files (x86)\Steam\steamapps\common\Burnout(TM) Paradise The Ultimate Box" `
    -ServerAddress <SERVER_IP>
```

This script:

1. Verifies your `BurnoutParadise.exe` hash, then writes a **separate** `BurnoutParadise.private.exe` beside it with
   the trusted certificate key replaced (your original is not changed and is re-verified afterwards).
2. Writes `steam_appid.txt` (containing `24740`) so Steam recognises the copy as the owned game.
3. Adds one hosts-file line: `<SERVER_IP> pcburnout08.ea.com` (a backup of your hosts file is saved first).
4. Adds a Windows Firewall rule for the game's peer-to-peer UDP ports on the local subnet (Private profile).

Undo everything: `Install-Client.ps1 -Remove`.

## 4. Play

1. Start **Steam** and stay signed in to the account that owns the game.
2. Launch `BurnoutParadise.private.exe` **from inside the game folder**.
3. Go to Online and sign in. **There is no registration screen: a new username creates the account**, using the
   password you typed. After that the password is required on every sign-in. The username is your in-game name.
4. One player hosts Freeburn; the others search for and join the game.

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| `Check-Connection` / game cannot reach the server | Firewall on the server for TCP 21841-21842; wrong `SERVER_IP`; hosts entry missing |
| Game says the connection failed straight away | Hosts entry missing/overridden; run `ping pcburnout08.ea.com` and confirm it shows `SERVER_IP` |
| Stuck on the first loading screen | The exe was started from the wrong folder; it must run from the game folder |
| Sign-in rejected | Wrong password for an existing username; or that username is already signed in elsewhere |
| Only 2 players can sign in | Default cap; raise `-MaxUsers` / `MAX_USERS` (more than 2 is untested) |
| Server IP changed (DHCP) | Re-run `Install-Client.ps1` with the new address, or give the server a fixed IP |

Game saves/profiles stay on each PC under `%LOCALAPPDATA%\Criterion Games\Burnout Paradise\Save`.
