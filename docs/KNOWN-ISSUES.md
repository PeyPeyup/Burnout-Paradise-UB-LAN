# Known issues and open work

* **In-game leaderboards are empty** (see PROTOCOL-NOTES). Road-rule records are being stored server-side for when this is solved.
* **Linux hosting is untested.** The linux-x64 build compiles and the launcher is written, but nobody has run it on Linux yet.
* **More than 2 players is untested** (`MAX_USERS`).
* **Passwords are stored in clear text** and the transport is SSL 3/RC4 with a public test CA. Do not expose the server
  to the open internet without hardening.
* **Profiles are local only**; there is no server-side career sync.
* **Server address changes break clients** (the hosts entry is a fixed IP). Use a fixed IP or DNS you control.
* **Ranked matches** were not investigated. Sending an invalid reply to some stats messages crashes the client.
* Only the Steam build 1.0.0.1 is supported by the patch script. Other builds (disc, Origin/EA App, Remastered) are not.
* Burnout Paradise Remastered is a different game with different services and is not supported.
* Steam Deck / Proton: untested.
