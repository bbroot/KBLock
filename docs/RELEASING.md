# Releasing LockIME

Releases run on GitHub Actions (`blacksmith-6vcpu-macos-latest`). Distribution
is **Developer ID + notarized** (non-sandboxed), with auto-updates via
**Sparkle** over two channels. Git tags are the single source of truth for
versions, and the workflows create them — you never push a tag by hand.

## Versioning model

- **Local builds are always `0.0.0-development`** (`project.yml`'s
  `MARKETING_VERSION`). Real versions exist only in CI, which overrides
  `MARKETING_VERSION` at archive time with a value computed from git tags by
  `scripts/ci/compute_version.sh`.
- **Stable** versions are `X.Y.Z`; **beta** versions are
  `X.Y.Z-beta.N`, where `X.Y.Z` is the latest stable tag and `N` continues
  from the highest existing `-beta.*` tag for that base.
- Every published build creates the matching `vX.Y.Z[-beta.N]` git tag and a
  GitHub Release carrying the zip. Beta releases are marked **pre-release**,
  so they are never shown as "Latest".
- An explicit stable version must be **newer than the latest stable tag** —
  backfill releases are rejected by `compute_version.sh` (a newer-created
  release would steal "Latest", and the date-stamped build number would top
  the appcast).
- **Bootstrap:** the very first release must be a stable one with an explicit
  version (e.g. `0.1.0`) — scheduled nightlies skip (and `compute_version.sh
  beta` refuses) until a stable tag exists to serve as the beta base.

## Channels

Two channels, two triggers — both end in `build-publish.yml`, the shared
reusable workflow (build, test, notarize, staple, tag, release, appcast):

- **Stable** — manual. Run the **Release** workflow (Actions → Release →
  Run workflow). Give it an explicit version, or leave the field empty to
  auto-bump the latest stable tag (the `bump` choice picks the segment:
  `patch` by default, or `minor` / `major`).
- **Beta** — the **nightly build**. `nightly.yml` runs every day at
  **01:00 UTC** (and on manual dispatch), builds the tip of `main`, and
  publishes it as `X.Y.Z-beta.N` to the beta channel. Scheduled runs are
  skipped when no commits landed since the last tagged build (every build
  tags its commit, so this means "nothing new to ship") and while no stable
  tag exists yet; manual dispatches always build.

**Build numbers are unified.** `build-publish.yml` sets `CFBundleVersion` to a
date-based stamp `YYYYMMDDHHMM` at build time (overriding `project.yml`).
`CFBundleVersion` is Sparkle's sort key, so "newest build by wall-clock time
wins" — stable and beta are directly comparable, and a beta follower always
lands on whichever build is actually newest, regardless of channel.

A version with a pre-release suffix entered in the Release workflow
(`1.2.3-rc.1`) is honored as a manual beta escape hatch — it ships to the beta
channel as a pre-release — but the normal beta path is the nightly.

The app's Updates settings let users opt into beta; the updater's
`allowedChannels` adds `beta` accordingly. Beta items are tagged
`sparkle:channel=beta`; stable items carry no channel tag (Sparkle's default),
so stable users never see nightlies while beta users see both and pick the newest.

## One-time setup

### 1. Sparkle EdDSA keys

The **public** key is already committed in `Info.plist` (`SUPublicEDKey`). Export
the matching **private** key from the keychain (generated with Sparkle's
`generate_keys`) and store it as a CI secret:

```sh
# from the Sparkle artifact bin/ directory
./generate_keys -x eddsa_private.pem      # exports the private key
# paste the file contents into the SPARKLE_EDDSA_PRIVATE_KEY secret
```

> The public key in `Info.plist` and the private key in CI must be a matched
> pair. Regenerating one requires updating the other.

### 2. Developer ID certificate

Export the **Developer ID Application** certificate as a `.p12` and base64-encode it:

```sh
base64 -i DeveloperID.p12 | pbcopy   # → DEVELOPER_ID_CERT_BASE64
```

### 3. Notarization key

Create an App Store Connect API key (Developer ID notarization) and note the
key ID, issuer ID, and the `.p8` contents.

### 4. gh-pages branch

Create an empty `gh-pages` branch; the workflow publishes `appcast.xml` there
(served at `https://oomol-lab.github.io/LockIME/appcast.xml`, the `SUFeedURL`).

## Required GitHub secrets

| Secret | Purpose |
|---|---|
| `DEVELOPER_ID_CERT_BASE64` | base64 of the Developer ID `.p12` |
| `DEVELOPER_ID_CERT_PASSWORD` | password for the `.p12` |
| `APPLE_TEAM_ID` | `PWJ9VF7HHT` |
| `APPLE_NOTARY_KEY` | contents of the App Store Connect `.p8` |
| `APPLE_NOTARY_KEY_ID` | API key ID |
| `APPLE_NOTARY_ISSUER` | API issuer ID |
| `SPARKLE_EDDSA_PRIVATE_KEY` | exported Sparkle private key |

## Cutting a release

1. Actions → **Release** → Run workflow. Optionally type the version
   (`1.2.3`); leave it empty to auto-bump the latest stable tag by the chosen
   segment (`patch` / `minor` / `major`). No file edit is ever needed —
   `project.yml` stays at `0.0.0-development`.
2. The workflow computes the version, builds, tests, archives (Developer ID,
   date-based build number), notarizes, staples, zips, runs `generate_appcast`
   (with `--channel beta` for pre-release versions), then creates the
   `vX.Y.Z` tag on the built commit, publishes the GitHub Release with the
   zip, and updates `appcast.xml` on `gh-pages`.

The signing order is strict: **codesign → notarize → staple → (re)zip**. The
distribution zip is produced *after* stapling.

## When a publish run fails

If a run fails **before** the "Tag & publish GitHub Release" step, nothing was
published — just re-run it (or dispatch again).

If it fails **after** the tag was created (e.g. the gh-pages step), prefer
**Re-run failed jobs**: the computed version is reused and the release step
updates the existing tag/release in place. A fresh dispatch with the *same
explicit version* also works as long as no new commits landed —
`compute_version.sh` allows an existing tag that points at the same commit and
re-publishes it. With auto-bump instead, the half-published tag would be
counted as the latest version and you would silently skip a number.

Do **not** re-run an old failed publish after a *newer* version has shipped:
the build number is stamped with the current time, so the re-run would sit on
top of the appcast and Sparkle would offer the older version as an "update".
Delete the stale tag/release and cut a new version instead.

## Testing the update flow locally

`make update-test-{none,download-fail,extract-fail,success}` exercises the full
in-app Sparkle pipeline (including install + relaunch) against a loopback feed
with a throwaway dev key — no production keys or `gh-pages` involved. See
`scripts/update-lab/README.md`.
