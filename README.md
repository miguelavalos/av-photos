# AV Photos

Open-source native photo sync client for `AV Photos`.

This repository is planned as the public home for an `iOS-first` app that syncs user-selected photos to Cloudflare R2 through an optional backend.

## Intended product shape

- native SwiftUI iOS app first
- optional account connection
- local-first selection and queueing
- hosted sync for `Pro` users
- self-hosted compatibility for users who do not want to use the Avalsys-hosted backend

## Current state

This repository now includes the initial native iOS scaffold under `apps/ios`.

Public roadmap and setup docs live in:

- [docs/roadmap.md](docs/roadmap.md)
- [docs/install-ios.md](docs/install-ios.md)
- [docs/release-process.md](docs/release-process.md)

Internal Avalsys planning may exist elsewhere, but this public repository should remain understandable on its own.

## Planned repository shape

```text
apps/
  ios/      SwiftUI iOS app
docs/
  install-ios.md
  release-process.md
```

## Local iOS setup

1. Go to `apps/ios`
2. Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig`
3. Generate the Xcode project:
   `xcodegen generate`
4. Open `AVPhotos.xcodeproj` in Xcode and run the `AVPhotos` scheme
