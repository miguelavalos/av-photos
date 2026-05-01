# AV Photos iOS Installation

This guide covers the current local iOS app foundation for `AV Photos`.

## Prerequisites

1. Xcode 16 or later
2. `xcodegen` installed locally
3. `bun` 1.3.13 or later
4. A local `.infisical/bootstrap.env`
5. A local `Config/Local.xcconfig` generated through Varlock, including `AVAPPS_ACCOUNT_PUBLISHABLE_KEY`

## Setup

1. From the repo root, install dependencies:
   `bun install`
2. Create your local bootstrap file at `.infisical/bootstrap.env`.
3. Generate the local config:
   `bun run ios:config`
4. Open `public/av-photos/apps/ios`
5. Adjust `apps/ios/Config/Local.xcconfig` only if you intentionally want local overrides
   Set `AVAPPS_API_BASE_URL` to the AV Apps backend for the selected profile.
6. Generate the project:
   `xcodegen generate`
7. Open `AVPhotos.xcodeproj`
8. Run the `AVPhotos` scheme on simulator or device

For production/App Store preparation:

```bash
bun run ios:config:production
```

`Local.xcconfig` is gitignored and should be regenerated locally instead of hand-maintained.

## Current scope

The current app foundation includes:

- SwiftUI shell
- photo-library permission flow
- library, sync, and profile tabs
- local client config pattern
- av-radio-aligned onboarding, continue-or-skip, language, and theme flows
- real AV Apps account sign-in through the configured account provider
- hosted backend reachability check
- authenticated remote asset listing using the signed-in account session or an explicit self-hosted backend token

It does not yet include:

- hosted upload integration
