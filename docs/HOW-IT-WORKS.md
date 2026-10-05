# How it works

```
 Game PC A ──TCP 21841 (SSL3 redirector)──▶ ┐
 Game PC B ──TCP 21842 (matchmaker)────────▶ │ MultiSocks server (this repo)
                                             ┘
 Game PC A ◀══════ UDP 1000 / 9615 / 9640 ═══════▶ Game PC B   (direct peer-to-peer)
```

## Connection sequence

1. The game resolves `pcburnout08.ea.com`. Your hosts entry points it at the server.
2. **Redirector (TCP 21841, SSL 3).** The game connects, completes an SSL 3 handshake offering RC4 suites `0x0005`
   and `0x0004`, and asks `@tic` / `@dir`. The server answers with the matchmaker address (same host, TCP 21842).
3. **Matchmaker (TCP 21842).** The game sends `addr`, `skey`, `news`, `sele`, then `auth` (username + obfuscated
   password), `pers`, and a series of lobby/stat requests (`usld`, `slst`, `rent`, `sviw`, `sdta`).
4. **Hosting.** `gpsc` creates a game on the server; `fupr`, `hchk` etc. keep presence updated.
5. **Joining.** A second client sends `gsea` (search) then `gjoi`; the server returns the host's addresses.
6. Gameplay traffic is **peer-to-peer UDP** on ports 1000, 9615 and 9640. The server is not involved.

## The certificate problem and the client patch

The game validates the redirector's certificate against an EA public key compiled into the executable
(`pcburnout08.ea.com` / "OTG3" authority). EA's private key is unavailable, so the game would reject any private
server. The client patch script therefore makes a copy of `BurnoutParadise.exe` in which:

1. The embedded 128-byte EA public key is replaced by the public key of the **eaEmu test certificate authority**
   (published in the eaEmu repository; the matching private key is public too). The server presents a certificate
   signed by that authority with the same structure as the historical one (512-bit RSA, MD5 signature, 936-byte DER).
2. A five-byte jump bypasses one certificate **host-name** comparison (error code `-24`) that failed even with the
   historical subject. The following embedded-authority signature check is left in place.

Both edits are hash-verified against the one tested build; any other build is refused. The original file is
never touched and its hash is re-verified after the copy is written.

## Accounts

* First sign-in with an unknown username creates the account with the supplied password.
* Later sign-ins must supply the same password (a wrong one is rejected). A blank password skips the check
  (an upstream console-compatibility quirk).
* One persona per account, named after the username. No rename: a new username is a new account.
* Only one concurrent sign-in per username.
* Storage: `static/local-accounts.json`, passwords in clear text.
* Player cap: `private_max_users` in `MultiSocks.json` (launcher parameter `-MaxUsers` / `MAX_USERS`; `0` = unlimited).

## Server changes versus upstream PSHome MultiServer (commit `8778e985e4fbbec9ee8f29d007d256dd1df5814f`)

* "Private pair mode" for the Burnout PC service: local account creation, no public-IP lookup, no automatic firewall
  edits, player cap.
* Redirector certificate matches the historical structure (`pcburnout08.ea.com`).
* Message capture logging (`[PrivateCapture]`) for stats/leaderboard messages.
* Road-rule uploads (`rrup`) stored in `static/road-rules.json` and acknowledged with `VALID=`.
* An optional experiment hook (`static/rr-experiment.json`) for trying reply layouts. Leave it absent in normal use.

## Saves

The game's career profile is a local file (`Profile.BurnoutParadiseSave`) on each PC. The server does not store or
sync profiles; it stores only accounts, personas, friends/rivals lists and road-rule uploads.
