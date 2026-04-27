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

1. Resolve the local iOS config from Infisical:
   `./scripts/generate-local-xcconfig.sh local`
2. Go to `apps/ios`
3. Generate the Xcode project:
   `xcodegen generate`
4. Open `AVPhotos.xcodeproj` in Xcode and run the `AVPhotos` scheme

## Local secrets

This repo follows the same local secret handling as `av-radio` for iOS builds:

- `apps/ios/Config/Local.xcconfig` is generated locally from `infisical`
- `.infisical/` stays out of git
- no real tokens or hosted endpoints should be committed

`varlock` is not wired here yet because this public repo currently ships only the native iOS client. If `av-photos` later adds a public web app or worker package, that part should follow the standard avalsys `varlock` + `infisical` baseline.
