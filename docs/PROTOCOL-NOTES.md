# Protocol notes (work in progress)

Findings from reverse engineering the game's client side. Contributions welcome.

## Message framing

`type(4 ASCII) + status(4, big-endian, absent when the name is 8 chars) + size(4, big-endian) + body`.
The body is `KEY=VALUE\n` lines. An 8-character name is `type + 4-char status`, e.g. `rrlctime` is a reply to `rrlc`
carrying the error status `time`.

## Road rules (Freeburn records)

| Message | Request | Notes |
| --- | --- | --- |
| `rrup` | `SKEY=frscores R=<rule ids> V=<values> C=<car ids> U=<user token> SET=<n>` | The game uploads its **whole career table** (zeros for unset rules). Values observed: times as integers (e.g. `5350`), showtime scores in the millions. The reply is read for a `VALID=<comma list>` key (the accepted rules). The server stores the latest non-zero value per player and rule. |
| `rrlc` | `SKEY=frscores NUM=10 IDX=0 SET=0|1|2` | Sent after event uploads, not when the Leaderboards menu opens. The game parses the reply body as a **raw comma list** (two header numbers, then numbers), not `KEY=VALUE`. |
| `rrgt` | `R=0,1,..9 SET=n` | Reply is read as raw `name,value` pairs. |

**Warning:** the game always consumes 10 rows per `rrlc`/`rrgt` page. A reply with fewer values leaves uninitialised
slots that are used as array indexes and **crash the game** (access violation). Pad replies to the full row count.

## Leaderboards screen (not working)

Online > Leaderboards sends `cate` then `snap` (`CHAN=5 VIEW=14Cars CI=0 II=0 VI=0 SEQN=1 COLS=1 START=0`). The upstream
server's `cate` reply is a leftover from Burnout 3 (`SYMS=TEST1,...`) and its `snap` reply carries no rows, so the table
is empty and cannot be navigated. The `sviw` reply format for stat views (`N, DESCS, NAMES, PARAMS, SYMS, TYPES, SS`) is
documented in the eaEmu sources. Strings used by the client's stats code: `SEQN RANGE FC CN%d CD%d CP%d CW%d CT%d CS%d
VIEW II COLS ~BUDDIES NAMES DESCS TYPES SLOT SYMS SS IC`. Working out the row delivery format is the main open task.

## Other messages seen

`opup` (driver/rider stats, comma lists), `rvup` (rivals), `fbst` (`DIST TIME RIVALS`), `fupr` (`PRES JOIN`),
`sdta` (`PERS SLOT VIEW`), `snap` (stat snapshot), `news` (contains `ROAD_RULES_SKEY=frscores`, `CHAL_SKEY=chalscores`).

## Ports

TCP 21841 (redirector), TCP 21842 (matchmaker); peer UDP 1000, 9615, 9640 (from the original manual).
