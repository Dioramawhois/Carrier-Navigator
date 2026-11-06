# Release procedure

Published on 2026-11-07: Workshop item 3834928522 and GitHub client beta 1.
SDK 0.10.0-dev and compatible CC2 ModLoader beta 11 were released separately.
All eight mod files and twelve SDK Workshop files were redownloaded and matched
against the staged payload hashes. GitHub release assets and the permanent
ModLoader beta channel were downloaded and verified too. See the publication
receipt in docs/verification/PUBLICATION_2026-11-07.json.

Official public title: **Carrier: Autopilot Waypoints**. Windows player packages
use **Carrier Autopilot Waypoints** without the colon. Existing repository URLs,
module/settings IDs and historical candidate folders remain stable.

The owner confirmed the fresh alpha.2 test and requested release preparation on
2026-11-06. **Do not publish the mod before the owner supplies its pictures.**
This is the owner's current instruction, not an additional approval requirement.

The owner subsequently tested alpha.4 in the ordinary Steam installation through
ModLoader with Revolution and requested publication. Record that general owner
acceptance in OWNER_ACCEPTANCE_ALPHA4_2026-11-07.json; retain alpha.2 as historical.
On 2026-11-07 the owner explicitly reconfirmed that publication must wait for
their pictures.

The owner then supplied the cover, stored at workshop/artwork/cover.png, and the
promo video https://www.youtube.com/watch?v=HidFBf5PSQg. The artwork condition is
fulfilled. Use the supplied cover and public video link for publication.

## Frozen gameplay

Release 0.1.0-client-beta.1 preserves accepted alpha4-loop-01 gameplay after the
helm/turning and loop fixes. The public title changes exactly three Lua string
literals; tools/release.py permits only those explicit substitutions, verifies
the original candidate hashes and records both old and new hashes. It does not
claim byte-identical functional files after this presentation update. The SDK
DLL must match the accepted candidate exactly. Do not rebuild that runtime to
clean up provenance labels; preserve the original build record and verify its
compiled input hashes against the corresponding source snapshot.

The owner's confirmation covers the revised experience generally. It does not
independently certify every save/load case, combat or countermeasure expenditure.
Preserve those limits and the single-player scope in public copy.

## Package surfaces

- Steam: mod.xml, LICENSE and the six runtime files only (eight files). No tests, tools,
  READMEs, evidence, ZIPs, SDK binaries, private observer or autoload driver.
- GitHub: all owned source, tests, tools, design notes, release copy and license.
  Also publish the SDK navigation source in its own repository/branch. Build
  caches, private saves, decompilation and credentials are never source inputs.
- GitHub release assets: player ZIP, full source ZIP, player guide, RELEASE.json
  and checksums. The native SDK, its corresponding source and third-party source
  notices are separate SDK assets.
- Artwork: wait for the owner's files. Preview/gallery files are Workshop upload
  metadata, not extra gameplay content. Do not invent a substitute preview.

## Validation and publication

Run the owned policy/UI regressions and release-package tests. Commit release
inputs, then run tools/release.py with the frozen candidate and acceptance JSON.
Its output separates steam, github and evidence directories. Never point the
Workshop uploader at the repository or the whole release directory.

Publish GitHub source independently of Workshop; release pages/assets remain
drafts while artwork is pending. Keep the existing SDK main-branch review rules.
Do not bypass protected branches to deliver the new motion interface.

Once pictures arrive, finish preview/gallery metadata, publish the prepared mod
and matching SDK dependency, then redownload each Workshop item. Compare every
payload hash and inspect descriptions, dependency links, version and picture.
Verify GitHub source/player downloads against the staged hashes as well. Only
then record publication as complete. Never upload discussion posts autonomously.
