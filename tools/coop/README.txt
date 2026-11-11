THE LAST ROADS / CO-OP PREVIEW

PLAY
Use launch-coop.cmd for the installed Steam runtime. The usual launch.cmd also
supports local network co-op. Choose Co-op / Steam friends on the title screen,
or press F6 during a journey. The host and all visitors choose a character and
one of eight recognition colors; an occupied color cannot be used twice.
The character preview shows the selected cloth color. Remote players have their
Steam nickname above their heads, or their character name on the local network.

STEAM
Steam test App ID 480 (Valve Spacewar) is configured by default, including the
packaged steam_appid.txt. No Steamworks registration is needed for this test.
Steam may display Spacewar as the game you are playing. Every friend should open
Steam and launch this same preview using Play.cmd before accepting an invite.
With this shared test App ID, accepting an invite while the preview is closed
may launch Spacewar instead; start the preview first.
To use your own App ID later, change steam_appid.txt or LAST_ROADS_STEAM_APP_ID.
The file overrides the project default, and the environment variable overrides
both. Keep Steam running and use the same game build on every computer. The Steam host creates a friends-only four-person lobby
and opens Invite friends. A running game accepts join_requested; an invitation
that launches the game is read from +connect_lobby. Both paths lead through the
character/color selection screen. Steam Networking Messages carries packets
through Valve's networking and relay system; no IP address entry is needed.
No invitations are sent automatically. A live test requires two Steam accounts
with access to the configured application. That test has not been completed.

LOCAL NETWORK
Host on LAN uses UDP port 27841 by default. Visitors enter the host computer's
local address and the same port. For several instances on one computer, use
127.0.0.1. The host counts as one of the four players.
Test-Local-Coop.cmd opens two windowed games with independent log files.
In window 1 choose Host on LAN; in window 2 choose Join host, address 127.0.0.1,
port 27841. Pick different character names and recognition colors. Menus and
switching focus do not pause the shared world. Steam invites need distinct
Steam identities; the two-window same-computer test uses LAN instead.

WEATHER
Clear daylight has depth-aware sun shafts, strongest and warmest around sunrise
and sunset. Clouds and rain fade them out; roofs, underground areas and night
suppress the effect. Shafts follow the sun and are shaped by scene geometry.

WORLD AND CHARACTERS
The host owns shared quests, named decisions, collected world objects, weather,
time and enemy simulation. Every player owns their character, pack, resources,
equipment and romance history. Enemies can target and damage visitors. Each
player can search a fallen enemy once for personal loot. Cleric Sanctuary heals
and protects nearby allies without stacking. Friendly fire is disabled.
Menus and conversations do not pause the party's world. A host leaving ends the
session; host migration is not implemented. Joining an active world starts near
the host. The host resumes its co-op world; visitors resume their own co-op
character before receiving the current host world.

SAVES
Co-op uses saves/coop/ with separate host and visitor character files. Solo
saves/hollow-valley.json and settings.cfg are not replaced. F5 saves co-op into
the co-op location while connected. Keep saves/ and settings.cfg when upgrading.

ART
assets/coop/ready/ contains 48 runtime sheets, generated with built-in
image_gen. Each has four temporal frames across and six action rows down:
idle, walk, run, fight, shoot, action (1152 cells total).
The six existing origins are Valdren, Shenari, Nambari, dwarf, elf and ogre;
the classes are warrior, mage, cleric and ranger. These are illustrated billboard
bodies in the game's existing style, with front-three-quarter poses and mirrored
facing. The female/ subdirectory adds 24 distinct female race/class sheets,
selected automatically by gender, including the co-op creator preview.
Separate back/side direction sheets are not included. Skin and metal keep their original colors;
only the cyan sash/cloth is recolored by the recognition shader.
Raw generator outputs remain in assets/coop/ and are excluded from game exports.
The importer removes only pale canvas connected to the background and keeps
interior highlights. Prompts: reports/coop/art-prompts.json.
Validation: reports/coop/art-validation.json.
Female prompts, hashes and validation: reports/coop/female/.

HOLLOW WEEPER
Her illustrated body and collider are now 20 percent larger (3.06 m tall).
All 15 supplied sounds/weeper MP3 recordings are connected: four laments,
two inhales, four screams, two recovery breaths, arm swing and two deaths.
Variants avoid immediate repeats; playback levels are balanced, silent lead-ins
trimmed, and short action cues faded to combat timing. Interrupted windups
do not produce a false scream. Original recordings remain unchanged.

VERIFY
powershell -File tools/check.ps1 -Only coop
powershell -File tools/coop/network-check.ps1
tools/godot-steam/godotsteam.452.editor.win64.console.exe --headless --path . --script tools/coop/check-steam-api.gd
The five-process network check covers host+three visitors, refusal of a fifth,
late joins, visitor movement, host enemy damage and damage arriving at a visitor,
world sync, personal identity and separate save destinations.
The visual check covers every sheet and frame, overhead names, recognition dye,
creator/menu UI, duplicate color/build rejection and ally Sanctuary.

DEPENDENCY
GodotSteam 4.24 / Godot 4.5.2 / Steamworks 1.65, pinned Windows archive:
https://codeberg.org/godotsteam/godotsteam/releases/tag/v4.24
SHA256 36b92f0c575875544ffc7bd9dd8bc161f34d4d7bd4d2867afec9ee893c63295a
Reinstall with tools/coop/setup-steam.ps1. Source license is retained in
tools/distribution-licenses/GODOTSTEAM_MIT.txt.
Steam invite behavior: https://partner.steamgames.com/doc/api/ISteamFriends
Steam messaging: https://partner.steamgames.com/doc/api/ISteamNetworkingMessages
