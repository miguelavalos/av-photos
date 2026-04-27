# AV Photos

Open-source native photo sync client for `AV Photos`.

This repository is planned as the public home for an `iOS-first` app that syncs user-selected photos to Cloudflare R2 through an optional backend.

## Intended product shape

- native SwiftUI iOS app first
- optional account connection
- local-first selection and queueing
- hosted sync for `Pro` users
- self-hosted compatibility for users who do not want to use the avalsys-hosted backend

## Current state

This repository now includes the initial native iOS scaffold under `apps/ios`.

Public roadmap and setup docs live in:

- [docs/roadmap.md](docs/roadmap.md)
- [docs/install-ios.md](docs/install-ios.md)
- [docs/release-process.md](docs/release-process.md)

Internal avalsys planning may exist elsewhere, but this public repository should remain understandable on its own.

## Planned repository shape

```text
apps/
  ios/      SwiftUI iOS app
docs/
  install-ios.md
  release-process.md
```

## Local iOS setup

1. Install repo tooling:
   `bun install`
2. Create the shared Infisical bootstrap:
   `cp .infisical/bootstrap.env.example .infisical/bootstrap.env`
3. Resolve the local iOS config through Varlock + Infisical:
   `bun run ios:config`
4. Go to `apps/ios`
5. Generate the Xcode project:
   `xcodegen generate`
6. Open `AVPhotos.xcodeproj` in Xcode and run the `AVPhotos` scheme

## Local secrets

This repo now follows the standard avalsys bootstrap pattern:

- `.infisical/bootstrap.env.example` is the committed template
- `.infisical/bootstrap.env` stays local-only and feeds `scripts/resolve-infisical-bootstrap-env.sh`
- `.env.schema` is the canonical client-config contract
- `apps/ios/Config/Local.xcconfig` is generated locally through `varlock printenv`
- no real tokens or hosted endpoints should be committed
