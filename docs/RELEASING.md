# Release procedure

Official public title: **Carrier: Autopilot Waypoints**. Windows player packages
use **Carrier Autopilot Waypoints** without the colon. Existing repository URLs,
module/settings IDs and historical candidate folders remain stable.

The owner confirmed the fresh alpha.2 test and requested release preparation on
2026-11-06. **Do not publish the mod before the owner supplies its pictures.**
This is the owner's current instruction, not an additional approval requirement.

The subsequent request adds helm animation and continuous power through turns.
Alpha.2 acceptance does not cover this new alpha.3 gameplay/runtime. Wait for the
owner's fresh check of alpha.3 as well; retain the older acceptance as historical.

Alpha.4 additionally repairs point-on-point route repetition in the integrated
ModLoader set. Its new loop gesture/closing segment need the owner's check.

## Frozen gameplay

Release 0.1.0-client-beta.1 must use a newly accepted candidate after alpha.3's
helm/turning and alpha.4 loop fixes. Its functional files and recorded SDK DLL must match
that accepted candidate exactly. Do not rebuild or substitute that runtime to
clean up provenance labels; preserve the original build record and verify its
compiled input hashes against the corresponding source snapshot.

The owner's confirmation covers the revised experience generally. It does not
independently certify every save/load case, combat or countermeasure expenditure.
Preserve those limits and the single-player scope in public copy.

## Package surfaces

- Steam: mod.xml, LICENSE and the seven runtime files only. No tests, tools,
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
