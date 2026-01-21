# Release (Homebrew Cask)

This project ships as a signed + notarized `.app` inside a Homebrew cask.

## GitHub Actions release flow

Tagging `v<version>` builds, signs, notarizes, uploads the zip to GitHub
Releases, and updates your Homebrew tap.

### Required GitHub secrets

- `SIGN_CERT_P12_BASE64` (base64-encoded Developer ID .p12)
- `SIGN_CERT_PASSWORD` (password for the .p12)
- `SIGN_IDENTITY` (e.g. `Developer ID Application: Your Name (TEAMID)`)
- `APPLE_ID`
- `TEAM_ID`
- `NOTARY_PASSWORD` (app-specific password)
- `NOTARY_PROFILE` (e.g. `notary`)
- `HOMEBREW_TAP_REPO` (defaults to `kluzzebass/homebrew-tap`)
- `HOMEBREW_TAP_TOKEN` (PAT with push access to tap repo)

### Tag a release

```bash
git tag v0.1.0
git push origin v0.1.0
```

## One-time setup

1. Join Apple Developer Program.
2. Create a **Developer ID Application** certificate.
3. Create a `.env` file (ignored by git):

```bash
APPLE_ID="you@example.com"
TEAM_ID="TEAMID"
NOTARY_PASSWORD="app-specific-password"
NOTARY_PROFILE="notary"
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
GITHUB_REPO="kluzzebass/transmissioner"
```

4. Store notarization credentials once:

```bash
xcrun notarytool store-credentials "$NOTARY_PROFILE" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$NOTARY_PASSWORD"
```

## Build + sign + notarize + zip

```bash
just cask-release
```

Artifacts are written to `dist/`:

- `Transmissioner-<version>.zip`
- `cask.rb` (ready to paste into your tap)

## Update the cask

1. Create a GitHub release at `v<version>` and upload
   `Transmissioner-<version>-<build>.zip`.
2. Update your tap with the contents of `dist/cask.rb`.

## Optional skip notarization (local testing only)

```bash
SKIP_NOTARIZE=1 \
just cask-release
```
