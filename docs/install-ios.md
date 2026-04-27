# AV Photos iOS Installation

This guide covers the current local scaffold for `AV Photos` on iOS.

## Prerequisites

1. Xcode 16 or later
2. `xcodegen` installed locally
3. `infisical` CLI available locally
4. A local `Config/Local.xcconfig` generated from Infisical

## Setup

1. From the repo root, generate the local config:
   `./scripts/generate-local-xcconfig.sh local`
2. Open `public/av-photos/apps/ios`
3. Adjust `apps/ios/Config/Local.xcconfig` only if you intentionally want local overrides
   Optional:
   - set `AVPHOTOS_AVAPPS_API_BASE_URL` to a hosted or self-hosted backend
   - set `AVPHOTOS_AUTH_TOKEN` to a local bearer token if you want to test authenticated hosted reads
4. Generate the project:
   `xcodegen generate`
5. Open `AVPhotos.xcodeproj`
6. Run the `AVPhotos` scheme on simulator or device

For production/App Store preparation:

```bash
./scripts/generate-local-xcconfig.sh production
```

`Local.xcconfig` is gitignored and should be regenerated locally instead of hand-maintained.

## Current scope

The current app scaffold includes:

- SwiftUI shell
- photo-library permission flow
- library, sync, and profile tabs
- local client config pattern
- av-radio-aligned onboarding, continue-or-skip, language, and theme flows
- hosted backend reachability check
- authenticated remote asset listing when a local auth token is configured

It does not yet include:

- real account auth
- hosted upload integration
